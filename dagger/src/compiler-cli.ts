import { dag, type Container, type Directory, type File } from "@dagger.io/dagger";
import { RUST_IMAGE } from "./consts.js";

const CARGO_HOME = "/cargo";
const CARGO_TARGET_DIR = "/target";

export function rustCompilerContainer(compiler: Directory): Container {
  return dag
    .container()
    .from(RUST_IMAGE)
    .withMountedDirectory("/src", compiler)
    .withWorkdir("/src")
    .withEnvVariable("CARGO_HOME", CARGO_HOME)
    .withEnvVariable("CARGO_TARGET_DIR", CARGO_TARGET_DIR)
    .withMountedCache(CARGO_HOME, dag.cacheVolume("beskid-cargo"))
    .withMountedCache(CARGO_TARGET_DIR, dag.cacheVolume("beskid-target"));
}

export function buildBeskidCli(compiler: Directory): Container {
  return rustCompilerContainer(compiler).withExec([
    "cargo",
    "build",
    "--release",
    "-p",
    "beskid_cli",
  ]);
}

export function beskidCliBinary(compiler: Directory): File {
  return buildBeskidCli(compiler).file(`${CARGO_TARGET_DIR}/release/beskid_cli`);
}
