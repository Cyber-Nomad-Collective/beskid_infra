import { dag, Directory } from "@dagger.io/dagger"
import { RUST_IMAGE, BUN_IMAGE, RUST_MIN_STACK } from "./consts.js"

/** Superrepo root (`compiler/…`) or an already-mounted `compiler/` tree. */
export async function resolveCompilerTree(source: Directory): Promise<Directory> {
  try {
    const cargo = await source.file("Cargo.toml").contents()
    if (cargo.includes("[workspace]")) {
      return source
    }
  } catch {
    // Not a compiler workspace root; treat `source` as the superrepo.
  }
  return source.directory("compiler")
}

/**
 * `cargo clippy` (deny warnings) then workspace tests under `compiler/`.
 */
async function mountBeskidBsol(
  source: Directory,
  ctr: ReturnType<typeof dag.container>,
): Promise<ReturnType<typeof dag.container>> {
  try {
    const bsol = source.directory("beskid_bsol")
    await bsol.file("crates/bsol/Cargo.toml").contents()
    return ctr.withMountedDirectory("/beskid_bsol", bsol)
  } catch {
    return ctr
  }
}

function compilerPreGateScript(): string {
  const patterns = [
    "expr_types",
    "TypeContext",
    "types/context/",
    "type_prefetched_source_path",
    "seed_definitions_from_source_path",
  ]
  const checks = patterns.map(
    (pattern) =>
      `if rg -n --glob '*.rs' '${pattern}' crates/ >/dev/null 2>&1; then echo "legacy type-system pattern reintroduced: ${pattern}" >&2; rg -n --glob '*.rs' '${pattern}' crates/ >&2 || true; exit 1; fi`,
  )
  return [
    "set -euo pipefail",
    "apt-get update -qq",
    "apt-get install -y -qq --no-install-recommends ripgrep",
    ...checks,
    'if [ -f scripts/verify-corelib-tests-parity.sh ]; then',
    "  bash scripts/verify-corelib-tests-parity.sh",
    "fi",
    "echo no legacy type-system patterns in compiler .rs sources",
  ].join("\n")
}

export async function compilerRustGate(source: Directory): Promise<string> {
  const compiler = await resolveCompilerTree(source)
  let ctr = dag
    .container()
    .from(RUST_IMAGE)
    .withMountedDirectory("/src", compiler)
    .withWorkdir("/src")
    .withEnvVariable("RUST_MIN_STACK", RUST_MIN_STACK)

  ctr = await mountBeskidBsol(source, ctr)

  await ctr
    .withExec(["bash", "-ec", compilerPreGateScript()])
    .withExec(["rustup", "component", "add", "clippy"])
    .withExec([
      "cargo",
      "clippy",
      "--workspace",
      "--all-targets",
      "--no-deps",
      "--",
      "-D",
      "warnings",
    ])
    .sync()

  return ctr
    .withExec(["bash", "scripts/ensure-runtime-bridge.sh"])
    .withExec([
      "cargo",
      "test",
      "--workspace",
      "--exclude",
      "beskid_e2e_tests",
      "--",
      "--test-threads=1",
    ])
    .stdout()
}

/**
 * Frozen Bun install and tests under `beskid_vscode/`.
 */
export async function vscodeGate(source: Directory): Promise<string> {
  const vscode = source.directory("beskid_vscode")

  return dag
    .container()
    .from(BUN_IMAGE)
    .withMountedDirectory("/work", vscode)
    .withWorkdir("/work")
    .withExec(["bun", "install", "--frozen-lockfile"])
    .withExec(["bun", "test"])
    .stdout()
}

export async function lspCommandContractGate(source: Directory): Promise<string> {
  const compiler = await resolveCompilerTree(source)
  const vscode = source.directory("beskid_vscode")

  const rustOut = await dag
    .container()
    .from(RUST_IMAGE)
    .withMountedDirectory("/src", compiler)
    .withWorkdir("/src")
    .withExec([
      "cargo",
      "test",
      "-p",
      "beskid_lsp",
      "project_explorer_command_contract_matches_snapshot",
      "--",
      "--nocapture",
    ])
    .stdout()

  const vscodeOut = await dag
    .container()
    .from(BUN_IMAGE)
    .withMountedDirectory("/work", vscode)
    .withWorkdir("/work")
    .withExec(["bun", "install", "--frozen-lockfile"])
    .withExec(["bun", "test", "test/lspCommandsContract.test.ts"])
    .stdout()

  return `${rustOut}\n${vscodeOut}`
}
