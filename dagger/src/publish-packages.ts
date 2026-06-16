import {
  func,
  object,
  type Directory,
  type Secret,
} from "@dagger.io/dagger";

import { corelibGate, corelibPublish } from "./corelib-gate.js";
import { corelibQuality } from "./corelib-quality.js";
import { corelibTest } from "./corelib-test.js";

@object()
export class PackagePublish {
  @func()
  async publishCorelib(
    source: Directory,
    pckgApiKey: Secret,
    pckgBaseUrl = "https://pckg.beskid-lang.org",
    versionBump = "patch",
  ): Promise<string> {
    return corelibPublish(source, pckgApiKey, pckgBaseUrl, versionBump);
  }

  @func()
  async publishTemplates(
    _source: Directory,
    _pckgApiKey: Secret,
    _pckgBaseUrl = "https://pckg.beskid-lang.org",
    _versionBump = "patch",
  ): Promise<string> {
    throw new Error(
      "publishTemplates is not implemented: templates publish pipeline pending.",
    );
  }
}

export { corelibGate, corelibQuality, corelibTest, corelibPublish };
