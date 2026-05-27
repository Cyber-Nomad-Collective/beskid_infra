import { fatal } from "./log.js";

const SEMVER_RE =
  /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$/;

export function assertValidSemver(version: string): void {
  if (!SEMVER_RE.test(version)) {
    fatal(
      `Derived extension version \`${version}\` is not valid semver. ` +
        "Use tag format vMAJOR.MINOR.PATCH for release builds.",
    );
  }
}
