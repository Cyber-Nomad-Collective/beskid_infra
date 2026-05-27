import { dag, type Directory, type Secret, func, object } from "@dagger.io/dagger";

const GIT_IMAGE = "alpine/git:2.47.2";

async function gitStdout(source: Directory, cmd: string): Promise<string> {
  return dag
    .container()
    .from(GIT_IMAGE)
    .withMountedDirectory("/src", source)
    .withWorkdir("/src")
    .withExec(["sh", "-ec", cmd])
    .stdout();
}

async function latestTag(
  source: Directory,
  tagPattern: string,
): Promise<string> {
  const cmd = `git describe --tags --abbrev=0 --match '${tagPattern}'`;
  const out = (await gitStdout(source, cmd)).trim();
  if (!out) {
    throw new Error(`No tag matching pattern '${tagPattern}' was found`);
  }
  return out;
}

function toMinorLine(tag: string): string {
  const normalized = tag.trim().replace(/^v/, "");
  const match = normalized.match(/^(\d+)\.(\d+)(?:\.\d+)?$/);
  if (!match) {
    throw new Error(
      `Tag '${tag}' is not in MAJOR.MINOR or MAJOR.MINOR.PATCH format`,
    );
  }
  return `${match[1]}.${match[2]}`;
}

@object()
export class Versioning {
  /**
   * Number of commits since the latest matching tag, scoped to a path.
   * Example:
   *   latest tag = v0.2
   *   commits since tag for path compiler/ = 121
   *   result = 121
   */
  @func()
  async commitsSinceLastTag(
    source: Directory,
    path: string,
    tagPattern = "v[0-9]*.[0-9]*",
  ): Promise<number> {
    const tag = await latestTag(source, tagPattern);
    const cmd = `git rev-list --count '${tag}'..HEAD -- '${path}'`;
    const out = (await gitStdout(source, cmd)).trim();
    const count = Number(out);
    if (!Number.isInteger(count) || count < 0) {
      throw new Error(`Invalid commit count output: '${out}'`);
    }
    return count;
  }

  /**
   * Build MAJOR.MINOR.COUNT from latest matching tag and commits for path.
   * Example: latest tag v0.2 and 121 commits -> 0.2.121
   */
  @func()
  async versionFromTagAndCommitCount(
    source: Directory,
    path: string,
    tagPattern = "v[0-9]*.[0-9]*",
  ): Promise<string> {
    const tag = await latestTag(source, tagPattern);
    const base = toMinorLine(tag);
    const count = await this.commitsSinceLastTag(source, path, tagPattern);
    return `${base}.${count}`;
  }

  /**
   * Optional: next semantic version from conventional commits (Daggerverse nsv).
   */
  @func()
  async nsvNextVersion(source: Directory, path?: string): Promise<string> {
    const nsv = (dag as any).nsv(source, "info");
    if (path && path.trim().length > 0) {
      return nsv.next({ paths: [path] });
    }
    return nsv.next();
  }

  /**
   * Create a GitHub release for a version tag using the Daggerverse GitHub module.
   */
  @func()
  async createGithubRelease(
    repo: string,
    versionTag: string,
    releaseTitle: string,
    releaseNotes: string,
    githubToken: Secret,
    targetCommitish = "main",
  ): Promise<string> {
    const ghVersion = "2.64.0";
    const base = dag.container().from("alpine:3.20").withExec([
      "apk",
      "add",
      "--no-cache",
      "git",
      "ca-certificates",
    ]);

    const withGh = (dag as any).github(ghVersion).installation(base);

    return withGh
      .withSecretVariable("GH_TOKEN", githubToken)
      .withExec([
        "gh",
        "release",
        "create",
        versionTag,
        "--repo",
        repo,
        "--target",
        targetCommitish,
        "--title",
        releaseTitle,
        "--notes",
        releaseNotes,
      ])
      .stdout();
  }
}
