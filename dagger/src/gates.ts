import { dag, Directory } from "@dagger.io/dagger"

const RUST_IMAGE = "rust:1-bookworm"
const BUN_IMAGE = "oven/bun:1.2"
const RUST_MIN_STACK = "67108864"

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
export async function compilerRustGate(source: Directory): Promise<string> {
  const compiler = await resolveCompilerTree(source)
  const ctr = dag
    .container()
    .from(RUST_IMAGE)
    .withMountedDirectory("/src", compiler)
    .withWorkdir("/src")
    .withEnvVariable("RUST_MIN_STACK", RUST_MIN_STACK)

  await ctr
    .withExec(["rustup", "component", "add", "clippy"])
    .withExec(["cargo", "clippy", "--workspace", "--all-targets"])
    .sync()

  return ctr.withExec(["cargo", "test", "--workspace"]).stdout()
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
