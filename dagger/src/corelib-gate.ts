import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import { dag, type Directory, type Secret } from "@dagger.io/dagger";

import { corelibQuality } from "./corelib-quality.js";
import { corelibTest } from "./corelib-test.js";
import { resolveCompilerTree, withCargoCaches } from "./gates.js";
import { resolveCorelibRoot } from "./lib/corelib-manifest.js";
import { RUST_IMAGE, RUST_MIN_STACK } from "./consts.js";
const moduleDir = dirname(fileURLToPath(import.meta.url));

function readPublishRunner(): string {
  return readFileSync(
    join(moduleDir, "lib", "corelib-publish-runner.mjs"),
    "utf-8",
  );
}

async function mountBeskidBsol(
  source: Directory,
  ctr: ReturnType<typeof dag.container>,
): Promise<ReturnType<typeof dag.container>> {
  try {
    const bsol = source.directory("beskid_bsol");
    await bsol.file("crates/bsol/Cargo.toml").contents();
    return ctr.withMountedDirectory("/beskid_bsol", bsol);
  } catch {
    return ctr;
  }
}

export async function corelibGate(source: Directory): Promise<string> {
  const quality = await corelibQuality(source);
  const tests = await corelibTest(source);
  return `${quality}\n${tests}`;
}

export async function corelibPublish(
  source: Directory,
  pckgApiKey: Secret,
  pckgBaseUrl = "https://pckg.beskid-lang.org",
  versionBump = "patch",
): Promise<string> {
  if (!["patch", "minor", "major"].includes(versionBump)) {
    throw new Error("versionBump must be patch, minor, or major");
  }

  await corelibQuality(source);

  const compiler = await resolveCompilerTree(source);
  const corelibRoot = await resolveCorelibRoot(source);
  const runner = readPublishRunner();

  let ctr = dag
    .container()
    .from(RUST_IMAGE)
    .withExec([
      "apk",
      "add",
      "--no-cache",
      // Alpine RUST_IMAGE has no bash; the publish step shells out to
      // scripts/ensure-runtime-bridge.sh (a bash script) below.
      "bash",
      "nodejs",
      "ca-certificates",
      "curl",
    ])
    .withMountedDirectory("/compiler", compiler)
    .withMountedDirectory("/corelib", corelibRoot)
    .withWorkdir("/compiler")
    .withEnvVariable("RUST_MIN_STACK", RUST_MIN_STACK)
    .withEnvVariable("CORELIB_ROOT", "/corelib")
    .withEnvVariable("BESKID_CORELIB_ROOT", "/corelib")
    .withEnvVariable("BESKID_PCKG_BASE_URL", pckgBaseUrl)
    .withEnvVariable("BESKID_PCKG_VERSION_BUMP", versionBump)
    .withSecretVariable("BESKID_PCKG_API_KEY", pckgApiKey)
    .withNewFile("/publish/corelib-publish-runner.mjs", runner, {
      permissions: 0o755,
    });

  ctr = withCargoCaches(ctr, "/compiler/target", "beskid-corelib-publish-target");
  ctr = await mountBeskidBsol(source, ctr);

  return ctr
    .withExec(["cargo", "build", "-p", "beskid_cli", "--release"])
    .withExec(["bash", "scripts/ensure-runtime-bridge.sh"])
    .withEnvVariable("BESKID_CLI_BIN", "/compiler/target/release/beskid_cli")
    .withExec(["node", "/publish/corelib-publish-runner.mjs"])
    .stdout();
}
