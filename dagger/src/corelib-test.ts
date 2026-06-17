import { dag, type Directory } from "@dagger.io/dagger";

import { resolveCompilerTree, withCargoCaches } from "./gates.js";
import {
  discoverProjectManifest,
  resolveCorelibRoot,
} from "./lib/corelib-manifest.js";
import { RUST_IMAGE, RUST_MIN_STACK } from "./consts.js";

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

async function testsWorkdir(source: Directory): Promise<string> {
  try {
    await source.file("compiler/Cargo.toml").contents();
    return "corelib/beskid_corelib/tests/corelib_tests";
  } catch {
    try {
      await source.file("Cargo.toml").contents();
      return "corelib/beskid_corelib/tests/corelib_tests";
    } catch {
      return "beskid_corelib/tests/corelib_tests";
    }
  }
}

export async function corelibTest(
  source: Directory,
  testTargetsFilter = "",
): Promise<string> {
  const compiler = await resolveCompilerTree(source);
  const corelibRoot = await resolveCorelibRoot(source);
  const testsDir = corelibRoot.directory("beskid_corelib/tests/corelib_tests");
  const manifestName = await discoverProjectManifest(testsDir);
  const testsCwd = await testsWorkdir(source);

  let ctr = dag
    .container()
    .from(RUST_IMAGE)
    .withMountedDirectory("/src", compiler)
    .withWorkdir("/src")
    .withEnvVariable("RUST_MIN_STACK", RUST_MIN_STACK);

  ctr = withCargoCaches(ctr, "/src/target", "beskid-corelib-target");
  ctr = await mountBeskidBsol(source, ctr);

  if (testTargetsFilter.trim()) {
    ctr = ctr.withEnvVariable(
      "BESKID_CORELIB_TEST_TARGETS",
      testTargetsFilter.trim(),
    );
  }

  return ctr
    .withExec(["cargo", "build", "-p", "beskid_cli", "--release"])
    .withExec(["bash", "scripts/ensure-runtime-bridge.sh"])
    .withExec([
      "bash",
      "-ec",
      [
        "CLI=/src/target/release/beskid_cli",
        `cd /src/${testsCwd}`,
        `"$CLI" test --project ${manifestName} --all-targets --plain`,
      ].join("\n"),
    ])
    .stdout();
}
