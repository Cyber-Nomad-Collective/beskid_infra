import {
  dag,
  func,
  object,
  type Directory,
  type File,
  type Platform,
  type Secret,
} from "@dagger.io/dagger";

import { compilerRustGate, resolveCompilerTree } from "./gates.js";
import { RUST_IMAGE } from "./consts.js";

const CARGO_TOML = "crates/beskid_cli/Cargo.toml";
const SEMVER_RE = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/;
const TAG_RE = /^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/;

export function cliReleaseTag(version: string): string {
  return `cli-v${version}`;
}

export function lspReleaseTag(version: string): string {
  return `lsp-v${version}`;
}

function parseSemver(version: string): [number, number, number] {
  const match = SEMVER_RE.exec(version.trim());
  if (!match) {
    throw new Error(`invalid semver: ${version}`);
  }
  return [Number(match[1]), Number(match[2]), Number(match[3])];
}

async function readPackageVersion(compiler: Directory): Promise<string> {
  const tree = await resolveCompilerTree(compiler);
  const content = await dag
    .container()
    .from(RUST_IMAGE)
    .withDirectory("/src", tree)
    .withWorkdir("/src")
    .file(CARGO_TOML)
    .contents();
  const match = content.match(/^version\s*=\s*"([^"]+)"/m);
  if (!match) {
    throw new Error(`failed to read version from ${CARGO_TOML}`);
  }
  return match[1];
}

function versionFromTag(githubRef: string, githubRefName: string): string | null {
  if (!githubRef.startsWith("refs/tags/")) {
    return null;
  }
  const tag = githubRefName.trim();
  const match = TAG_RE.exec(tag);
  if (!match) {
    throw new Error(
      `Tag ${tag} is not semver (expected vMAJOR.MINOR.PATCH, e.g. v0.1.0)`,
    );
  }
  return tag.replace(/^v/, "");
}

/** Port of `compiler/ci/version.py` `resolve_version`. */
export async function resolveCliVersion(
  compiler: Directory,
  githubRef: string,
  githubRefName: string,
  githubRunNumber: string,
): Promise<string> {
  const tagged = versionFromTag(githubRef, githubRefName);
  if (tagged !== null) {
    return tagged;
  }

  if (githubRef && githubRef !== "refs/heads/main") {
    throw new Error(`Unexpected GITHUB_REF for version resolution: ${githubRef}`);
  }

  const base = await readPackageVersion(compiler);
  const [major, minor, patch] = parseSemver(base);

  const latestTag = await gitDescribeLatestSemverTag(compiler);
  if (latestTag) {
    const tagMatch = TAG_RE.exec(latestTag);
    if (!tagMatch) {
      throw new Error(`Latest tag ${latestTag} is not semver`);
    }
    const tMajor = Number(tagMatch[1]);
    const tMinor = Number(tagMatch[2]);
    const tPatch = Number(tagMatch[3]);
    const commitsSince = await gitRevListCount(compiler, `${latestTag}..HEAD`);
    if (commitsSince <= 0) {
      return `${tMajor}.${tMinor}.${tPatch}`;
    }
    return `${tMajor}.${tMinor}.${tPatch + commitsSince}`;
  }

  if (/^\d+$/.test(githubRunNumber.trim())) {
    return `${major}.${minor}.${patch + Number(githubRunNumber)}`;
  }

  return base;
}

async function gitExec(compiler: Directory, args: string[]): Promise<string> {
  const tree = await resolveCompilerTree(compiler);
  try {
    return await dag
      .container()
      .from(RUST_IMAGE)
      .withExec([
        "apk",
        "add",
        "--no-cache",
        "git",
      ])
      .withDirectory("/src", tree)
      .withWorkdir("/src")
      .withExec(["git", ...args])
      .stdout();
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    throw new Error(`git ${args.join(" ")} failed: ${message}`);
  }
}

async function gitDescribeLatestSemverTag(compiler: Directory): Promise<string | null> {
  try {
    const out = await gitExec(compiler, [
      "describe",
      "--tags",
      "--abbrev=0",
      "--match",
      "v[0-9]*.[0-9]*.[0-9]*",
    ]);
    return out.trim() || null;
  } catch {
    return null;
  }
}

async function gitRevListCount(compiler: Directory, range: string): Promise<number> {
  const out = await gitExec(compiler, ["rev-list", "--count", range]);
  return Number(out.trim());
}

function patchCargoTomlScript(version: string): string {
  const escaped = version.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
  return `sed -i 's/^version = ".*"/version = "${escaped}"/' ${CARGO_TOML}`;
}

function patchCargoTomlPowerShell(version: string): string {
  const escaped = version.replace(/'/g, "''");
  return `$p='${CARGO_TOML}'; (Get-Content $p) -replace '^version = \\".*\\"', 'version = \\"${escaped}\\"' | Set-Content $p`;
}

function ociPlatformForTarget(target: string): Platform {
  switch (target) {
    case "x86_64-unknown-linux-gnu":
      return "linux/amd64" as Platform;
    case "aarch64-apple-darwin":
      return "darwin/arm64" as Platform;
    case "x86_64-pc-windows-msvc":
      return "windows/amd64" as Platform;
    default:
      throw new Error(`unsupported release target: ${target}`);
  }
}

function releaseBinaryPath(target: string, packageBinary: string, runnerOs: string): string {
  const base = `target/${target}/release/${packageBinary}`;
  return runnerOs === "Windows" ? `${base}.exe` : base;
}

async function buildReleaseArtifact(
  compiler: Directory,
  releaseVersion: string,
  target: string,
  assetName: string,
  runnerOs: string,
  packageName: string,
  packageBinary: string,
): Promise<File> {
  await compilerRustGate(compiler);
  const compilerTree = await resolveCompilerTree(compiler);
  const platform = ociPlatformForTarget(target);

  let ctr = dag
    .container({ platform })
    .from(RUST_IMAGE)
    .withDirectory("/src", compilerTree)
    .withWorkdir("/src");

  if (runnerOs === "Windows") {
    ctr = ctr.withExec([
      "powershell",
      "-NoProfile",
      "-Command",
      patchCargoTomlPowerShell(releaseVersion),
    ]);
  } else {
    ctr = ctr.withExec(["sh", "-ec", patchCargoTomlScript(releaseVersion)]);
  }

  ctr = ctr
    .withExec(["rustup", "target", "add", target])
    .withExec([
      "cargo",
      "build",
      "-p",
      packageName,
      "--release",
      "--target",
      target,
    ]);

  return ctr.file(releaseBinaryPath(target, packageBinary, runnerOs)).withName(assetName);
}

function releaseStreamConfig(stream: string): {
  versionFile: string;
  immutableTag: (v: string) => string;
  rollingTag: string;
  immutableName: (v: string) => string;
  rollingName: string;
  assetGlob: string;
} {
  switch (stream) {
    case "cli":
      return {
        versionFile: "cli-version.txt",
        immutableTag: (v) => `cli-v${v}`,
        rollingTag: "cli-latest",
        immutableName: (v) => `Beskid CLI v${v}`,
        rollingName: "Beskid CLI (rolling)",
        assetGlob: "beskid-*",
      };
    case "lsp":
      return {
        versionFile: "lsp-version.txt",
        immutableTag: (v) => `lsp-v${v}`,
        rollingTag: "lsp-latest",
        immutableName: (v) => `Beskid LSP v${v}`,
        rollingName: "Beskid LSP (rolling)",
        assetGlob: "beskid_lsp-*",
      };
    default:
      throw new Error(`Unsupported release stream: ${stream}`);
  }
}

async function publishReleaseStream(
  releaseStream: string,
  releaseVersion: string,
  compilerSha: string,
  assets: Directory,
  githubToken: Secret,
): Promise<string> {
  const cfg = releaseStreamConfig(releaseStream);
  const repo = "Cyber-Nomad-Collective/beskid_compiler";
  const immutableTag = cfg.immutableTag(releaseVersion);
  const immutableBody = `Immutable ${releaseStream.toUpperCase()} release for version \`${releaseVersion}\`.

**Commit:** \`${compilerSha}\`

For the rolling build that tracks \`main\`, use the [${cfg.rollingTag}](https://github.com/${repo}/releases/tag/${cfg.rollingTag}) release instead.`;

  const rollingBody = `Rolling ${releaseStream.toUpperCase()} build.

**Version string:** \`${releaseVersion}\`
**Commit:** \`${compilerSha}\``;

  const script = [
    "set -euo pipefail",
    `printf '%s\\n' '${releaseVersion}' > /assets/${cfg.versionFile}`,
    `cd /assets`,
    `immutable_tag='${immutableTag}'`,
    `rolling_tag='${cfg.rollingTag}'`,
    `if gh release view "$immutable_tag" --repo '${repo}' >/dev/null 2>&1; then`,
    `  gh release upload "$immutable_tag" --repo '${repo}' *`,
    `else`,
    `  gh release create "$immutable_tag" --repo '${repo}' --target '${compilerSha}' --title '${cfg.immutableName(releaseVersion)}' --notes '${immutableBody.replace(/'/g, "'\\''")}' *`,
    `fi`,
    `if gh release view "$rolling_tag" --repo '${repo}' >/dev/null 2>&1; then`,
    `  gh release upload "$rolling_tag" --repo '${repo}' * --clobber`,
    `else`,
    `  gh release create "$rolling_tag" --repo '${repo}' --target '${compilerSha}' --title '${cfg.rollingName}' --notes '${rollingBody.replace(/'/g, "'\\''")}' *`,
    `fi`,
    `echo compiler-release-publish: OK (${releaseStream} ${releaseVersion} @ ${compilerSha})`,
  ].join("\n");

  return dag
    .container()
    .from("alpine:3.20")
    .withExec([
      "apk",
      "add",
      "--no-cache",
      "git",
      "ca-certificates",
      "github-cli",
    ])
    .withMountedDirectory("/assets", assets)
    .withSecretVariable("GH_TOKEN", githubToken)
    .withExec(["sh", "-ec", script])
    .stdout();
}

@object()
export class CompilerRelease {
  /** Port of `ci.version_job` + `version.resolve_version` (stdout is the version string). */
  @func()
  async computeCliVersion(
    compilerSource: Directory,
    githubRef: string,
    githubRefName: string,
    githubEventName: string,
    githubRunNumber: string = "",
  ): Promise<string> {
    if (githubEventName !== "push") {
      throw new Error(
        `computeCliVersion expects githubEventName=push, got ${githubEventName}`,
      );
    }
    if (
      !githubRef.startsWith("refs/tags/v") &&
      githubRef !== "refs/heads/main"
    ) {
      throw new Error(`Unexpected GITHUB_REF for version job: ${githubRef}`);
    }
    return resolveCliVersion(
      compilerSource,
      githubRef,
      githubRefName,
      githubRunNumber,
    );
  }

  /** Port of `ci.release_cli` after `compilerRustGate`. */
  @func()
  async buildCliRelease(
    compilerSource: Directory,
    releaseVersion: string,
    target: string,
    assetName: string,
    runnerOs: string = "Linux",
  ): Promise<File> {
    return buildReleaseArtifact(
      compilerSource,
      releaseVersion,
      target,
      assetName,
      runnerOs,
      "beskid_cli",
      "beskid_cli",
    );
  }

  /** Port of `ci.release_lsp` after `compilerRustGate`. */
  @func()
  async buildLspRelease(
    compilerSource: Directory,
    releaseVersion: string,
    target: string,
    assetName: string,
    runnerOs: string = "Linux",
  ): Promise<File> {
    return buildReleaseArtifact(
      compilerSource,
      releaseVersion,
      target,
      assetName,
      runnerOs,
      "beskid_lsp",
      "beskid_lsp",
    );
  }

  @func()
  async publishReleaseStream(
    releaseStream: string,
    releaseVersion: string,
    compilerSha: string,
    assets: Directory,
    githubToken: Secret,
  ): Promise<string> {
    return publishReleaseStream(
      releaseStream,
      releaseVersion,
      compilerSha,
      assets,
      githubToken,
    );
  }
}
