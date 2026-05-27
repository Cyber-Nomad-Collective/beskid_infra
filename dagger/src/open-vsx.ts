import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import { dag, type Directory, type File } from "@dagger.io/dagger";

import { compilerRustGate, vscodeGate } from "./gates.js";
import { requireEnv, secretFromEnv, withSecrets } from "./lib/env.js";
import { info, fatal } from "./lib/log.js";
import {
  compilerReleaseBinPath,
  containerPlatform,
} from "./lib/platform.js";
import { assertValidSemver } from "./lib/semver.js";
import {
  initBeskidVscodeSubmodule,
  initCompilerSubmodule,
} from "./lib/submodule.js";
import { buildBeskidLsp } from "./lsp-build.js";

const moduleDir = dirname(fileURLToPath(import.meta.url));

function readScript(name: string): string {
  return readFileSync(join(moduleDir, "..", "scripts", name), "utf-8");
}

function bunPublishContainer(
  source: Directory,
  lspBin: File,
  vsPlatform: string,
  binName: string,
  token: string,
): ReturnType<typeof dag.container> {
  const serverDir = `beskid_vscode/server/${vsPlatform}`;
  const resolveScript = readScript("resolve-extension-version.sh");
  const publishScript = readScript("open-vsx-bundle-publish.sh");

  let ctr = withSecrets(
    dag
      .container({ platform: containerPlatform(vsPlatform) })
      .from("oven/bun:1.2.20-debian")
      .withExec(["apt-get", "update"])
      .withExec([
        "apt-get",
        "install",
        "-y",
        "--no-install-recommends",
        "git",
        "ca-certificates",
      ])
      .withDirectory("/src", source)
      .withWorkdir("/src")
      .withEnvVariable("BESKID_REPO_ROOT", "/src")
      .withEnvVariable("OVSX_TOKEN", token)
      .withFile(`/src/${serverDir}/${binName}`, lspBin)
      .withNewFile(
        "/src/beskid_infra/dagger/scripts/resolve-extension-version.sh",
        resolveScript,
        { permissions: 0o755 },
      )
      .withNewFile(
        "/src/beskid_infra/dagger/scripts/open-vsx-bundle-publish.sh",
        publishScript,
        { permissions: 0o755 },
      ),
    [
      "OVSX_TOKEN",
      "GITHUB_REF_NAME",
      "GITHUB_REF_TYPE",
      "COMPILER_SUBMODULE_TOKEN",
      "BESKID_VSCODE_SUBMODULE_TOKEN",
    ],
  );

  if (!vsPlatform.startsWith("win32")) {
    ctr = ctr.withExec(["chmod", "+x", `/src/${serverDir}/${binName}`]);
  }

  return ctr.withExec([
    "bash",
    "/src/beskid_infra/dagger/scripts/open-vsx-bundle-publish.sh",
    vsPlatform,
    binName,
    token,
  ]);
}

/** Open VSX publish: gates → LSP build → bundle, VSIX, ovsx publish. */
export async function openVsxPublish(
  source: Directory,
  platform: string,
  binName: string,
  rustTarget = "",
): Promise<void> {
  if (!platform.trim() || !binName.trim()) {
    fatal(
      "Set platform and binName (e.g. linux-x64, beskid_lsp). " +
        "Optional rustTarget for cross-compiles (e.g. x86_64-apple-darwin for darwin-x64).",
    );
  }

  const token = requireEnv("OVSX_TOKEN");
  secretFromEnv("OVSX_TOKEN");

  const target = rustTarget.trim();
  info(
    `Open VSX: platform=${platform} bin=${binName} rustTarget=${target || "(native)"}`,
  );

  let tree = await initBeskidVscodeSubmodule(source);
  await vscodeGate(tree);
  tree = await initCompilerSubmodule(tree);
  await compilerRustGate(tree);

  const built = buildBeskidLsp(tree, platform, binName, target);
  const binPath = `/src/${compilerReleaseBinPath(binName, target)}`;
  const lspBin = built.file(binPath);

  info(
    `Open VSX: bundling ${binName} for platform=${platform} (vscode root=beskid_vscode)`,
  );

  const resolved =
    process.env.GITHUB_REF_TYPE === "tag"
      ? (process.env.GITHUB_REF_NAME ?? "").replace(/^v/, "")
      : null;
  if (resolved) {
    assertValidSemver(resolved);
  }

  await bunPublishContainer(tree, lspBin, platform, binName, token).sync();

  info("Open VSX: publish complete");
}
