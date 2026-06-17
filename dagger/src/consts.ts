/** Rust container image used for compiler build and test pipelines. */
export const RUST_IMAGE =
  "rust:alpine@sha256:42cc159f02dd5f56e62f5131c54fb3c321050ba5660b04e54d348f3e21ac1dbf";

/** Bun container image used for JavaScript/TypeScript tooling. */
export const BUN_IMAGE = "oven/bun:1.2";

/** Minimum stack size for the Rust compiler (avoids stack overflow on deep ASTs). */
export const RUST_MIN_STACK = "67108864";
