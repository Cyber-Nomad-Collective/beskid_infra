import {
  func,
  object,
  type Directory,
  type Secret,
} from "@dagger.io/dagger";

@object()
export class PackagePublish {
  /**
   * Python CI scripts were intentionally removed from centralized CI.
   * Keep function signatures for compatibility; implementation to be replaced
   * with native Dagger/CLI publish pipeline.
   */
  @func()
  async publishCorelib(
    _source: Directory,
    _compiler: Directory,
    _pckgApiKey: Secret,
    _pckgBaseUrl = "https://pckg.beskid-lang.org",
    _versionBump = "patch",
  ): Promise<string> {
    throw new Error(
      "publishCorelib is temporarily disabled: legacy Python publish scripts were removed from centralized CI.",
    );
  }

  /**
   * Python CI scripts were intentionally removed from centralized CI.
   * Keep function signatures for compatibility; implementation to be replaced
   * with native Dagger/CLI publish pipeline.
   */
  @func()
  async publishTemplates(
    _source: Directory,
    _compiler: Directory,
    _pckgApiKey: Secret,
    _pckgBaseUrl = "https://pckg.beskid-lang.org",
    _versionBump = "patch",
  ): Promise<string> {
    throw new Error(
      "publishTemplates is temporarily disabled: legacy Python publish scripts were removed from centralized CI.",
    );
  }
}
