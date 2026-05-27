import type { Platform } from "@dagger.io/dagger";

import { fatal } from "./log.js";

/** VS Code / vsce platform id → OCI platform for Dagger containers. */
export function containerPlatform(vsPlatform: string): Platform {
  let oci: string;
  switch (vsPlatform) {
    case "linux-x64":
      oci = "linux/amd64";
      break;
    case "darwin-arm64":
      oci = "darwin/arm64";
      break;
    case "darwin-x64":
      oci = "darwin/amd64";
      break;
    case "win32-x64":
      oci = "windows/amd64";
      break;
    default:
      return fatal(`Unsupported OPENVSX platform: ${vsPlatform}`);
  }
  return oci as Platform;
}

export function compilerReleaseBinPath(
  binName: string,
  rustTarget: string,
): string {
  if (rustTarget) {
    return `compiler/target/${rustTarget}/release/${binName}`;
  }
  return `compiler/target/release/${binName}`;
}
