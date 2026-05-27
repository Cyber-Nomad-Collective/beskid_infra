import { dag, type Container, type Directory } from "@dagger.io/dagger";

import { containerPlatform } from "./lib/platform.js";
import { withSecrets } from "./lib/env.js";

/** Build `beskid_lsp` release binary for the target VS Code platform. */
export function buildBeskidLsp(
  source: Directory,
  vsPlatform: string,
  binName: string,
  rustTarget: string,
): Container {
  let ctr = withSecrets(
    dag
      .container({ platform: containerPlatform(vsPlatform) })
      .from("rust:1-bookworm")
      .withDirectory("/src", source)
      .withWorkdir("/src/compiler")
      .withMountedCache("/usr/local/cargo/registry", dag.cacheVolume("cargo-registry"))
      .withMountedCache("/src/compiler/target", dag.cacheVolume("beskid-compiler-target")),
    ["COMPILER_SUBMODULE_TOKEN"],
  );

  if (rustTarget) {
    ctr = ctr.withExec(["rustup", "target", "add", rustTarget]);
  }

  const cargoArgs = ["cargo", "build", "-p", "beskid_lsp", "--release"];
  if (rustTarget) {
    cargoArgs.push("--target", rustTarget);
  }

  return ctr.withExec(cargoArgs);
}
