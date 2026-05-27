import { func, object, type Directory } from "@dagger.io/dagger";

import { compilerRustGate, vscodeGate } from "./gates.js";
import { openVsxPublish } from "./open-vsx.js";

export { CompilerRelease } from "./compiler-release.js";
export { PackagePublish } from "./publish-packages.js";
export { Versioning } from "./versioning.js";

@object()
export class BeskidCi {
  @func()
  async compilerRustGate(source: Directory): Promise<string> {
    return compilerRustGate(source);
  }

  @func()
  async vscodeGate(source: Directory): Promise<string> {
    return vscodeGate(source);
  }

  @func()
  async openVsxPublish(
    source: Directory,
    platform: string,
    binName: string,
    rustTarget = "",
  ): Promise<void> {
    return openVsxPublish(source, platform, binName, rustTarget);
  }
}
