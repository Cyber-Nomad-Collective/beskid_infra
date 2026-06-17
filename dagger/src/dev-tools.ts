import { dag, type Directory } from "@dagger.io/dagger";

import { resolveCompilerTree } from "./gates.js";
import { RUST_IMAGE } from "./consts.js";

export async function blessFormatFixtures(source: Directory): Promise<string> {
  const compiler = await resolveCompilerTree(source);
  const script = [
    "set -euo pipefail",
    "cargo build -p beskid_cli --quiet",
    'CLI=target/debug/beskid_cli',
    '[ -x "$CLI" ] || CLI=target/release/beskid_cli',
    'fixture_root=crates/beskid_tests/fixtures/format',
    'shopt -s globstar nullglob',
    'for inp in "$fixture_root"/**/*.input.bd; do',
    '  out="${inp%.input.bd}.expected.bd"',
    '  "$CLI" format "$inp" > "$out"',
    '  echo "blessed $out"',
    "done",
  ].join("\n");

  return dag
    .container()
    .from(RUST_IMAGE)
    .withMountedDirectory("/src", compiler)
    .withWorkdir("/src")
    .withExec(["bash", "-ec", script])
    .stdout();
}

export async function formatCorpusCheck(source: Directory): Promise<string> {
  const compiler = await resolveCompilerTree(source);
  const script = [
    "set -euo pipefail",
    "cargo build -p beskid_cli --release --quiet",
    'CLI=target/release/beskid_cli',
    'corpus=corelib/beskid_corelib',
    'if [ ! -d "$corpus" ]; then echo "skip format corpus (no corelib tree)"; exit 0; fi',
    'find "$corpus" -name "*.bd" -print0 | while IFS= read -r -d "" f; do',
    '  "$CLI" format --check "$f" || exit 1',
    "done",
    'echo "format corpus OK"',
  ].join("\n");

  return dag
    .container()
    .from(RUST_IMAGE)
    .withMountedDirectory("/src", compiler)
    .withWorkdir("/src")
    .withExec(["bash", "-ec", script])
    .stdout();
}
