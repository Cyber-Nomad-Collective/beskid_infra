import { func, object, type Directory } from "@dagger.io/dagger";

import { compilerRustGate, lspCommandContractGate, vscodeGate } from "./gates.js";
import { openVsxPublish } from "./open-vsx.js";
import { resolveCliVersion } from "./compiler-release.js";
import { corelibGate } from "./corelib-gate.js";
import { platformSmoke, siteBuildGate } from "./platform-gates.js";
import { blessFormatFixtures, formatCorpusCheck } from "./dev-tools.js";

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
  async lspCommandContractGate(source: Directory): Promise<string> {
    return lspCommandContractGate(source);
  }

  @func()
  async vscodeGate(source: Directory): Promise<string> {
    return vscodeGate(source);
  }

  @func()
  async corelibGate(source: Directory): Promise<string> {
    return corelibGate(source);
  }

  @func()
  async platformSmoke(source: Directory): Promise<string> {
    return platformSmoke(source);
  }

  @func()
  async siteBuildGate(
    source: Directory,
    app: string,
    nodeAuthToken = "",
  ): Promise<string> {
    if (app !== "auth" && app !== "platform-spec") {
      throw new Error("app must be auth or platform-spec");
    }
    return siteBuildGate(source, app, nodeAuthToken);
  }

  @func()
  async blessFormatFixtures(source: Directory): Promise<string> {
    return blessFormatFixtures(source);
  }

  @func()
  async formatCorpusCheck(source: Directory): Promise<string> {
    return formatCorpusCheck(source);
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

  /** Rolling CLI/LSP semver (port of former compiler/ci/version.py). */
  @func()
  async computeCliVersion(
    source: Directory,
    githubRef: string,
    githubRefName: string,
    githubEventName: string,
    githubRunNumber = "",
  ): Promise<string> {
    if (githubEventName !== "push") {
      throw new Error(
        `computeCliVersion expects githubEventName=push, got ${githubEventName}`,
      );
    }
    if (
      !githubRef.startsWith("refs/tags/v") &&
      githubRef !== "refs/heads/main"
    ) {
      throw new Error(`Unexpected GITHUB_REF for version job: ${githubRef}`);
    }
    return resolveCliVersion(
      source,
      githubRef,
      githubRefName,
      githubRunNumber,
    );
  }
}
