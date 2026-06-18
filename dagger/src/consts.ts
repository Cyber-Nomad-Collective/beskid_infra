/** Rust container image used for compiler build and test pipelines. */
export const RUST_IMAGE =
  "rust:alpine@sha256:42cc159f02dd5f56e62f5131c54fb3c321050ba5660b04e54d348f3e21ac1dbf";

/**
 * Bun container image used for JavaScript/TypeScript tooling.
 * Pinned by digest (oven/bun:1.2) so CI inputs are reproducible. Bump the
 * digest deliberately rather than tracking a floating tag.
 */
export const BUN_IMAGE =
  "oven/bun:1.2@sha256:6ebf306367da43ad75c4d5119563e24de9b66372929ad4fa31546be053a16f74";

/** Minimum stack size for the Rust compiler (avoids stack overflow on deep ASTs). */
export const RUST_MIN_STACK = "67108864";

/**
 * Cargo registry/index path inside the Rust image. Mounting a cache volume on
 * this subdirectory (not all of CARGO_HOME) keeps the toolchain binaries in
 * /usr/local/cargo/bin intact while reusing downloaded crates across runs.
 */
export const CARGO_REGISTRY_DIR = "/usr/local/cargo/registry";

/** Shared cache volume for the cargo registry/index, reused by every Rust pipeline. */
export const CARGO_REGISTRY_CACHE = "cargo-registry";
