import { dag, type Directory } from "@dagger.io/dagger";

const BUN_IMAGE = "oven/bun:1.2";

export async function siteBuildGate(
  source: Directory,
  app: "auth" | "platform-spec",
  nodeAuthToken = "",
): Promise<string> {
  let ctr = dag
    .container()
    .from(BUN_IMAGE)
    .withMountedDirectory("/src", source)
    .withWorkdir("/src");

  if (nodeAuthToken.trim()) {
    ctr = ctr.withEnvVariable("NODE_AUTH_TOKEN", nodeAuthToken.trim());
  }

  if (app === "auth") {
    return ctr
      .withExec(["sh", "-ec", "cd site/auth && bun install --frozen-lockfile"])
      .withExec(["sh", "-ec", "cd site/auth && bun run test"])
      .withExec([
        "sh",
        "-ec",
        "cd site/auth && SKIP_ENV_VALIDATION=1 bun run build",
      ])
      .withExec([
        "sh",
        "-ec",
        "cd site/auth && bun run verify:client-bundle",
      ])
      .withExec(["sh", "-ec", "cd site/auth && bun run test:bundle"])
      .stdout();
  }

  return ctr
    .withExec([
      "sh",
      "-ec",
      "cd beskid_web_common && bun install --frozen-lockfile",
    ])
    .withExec([
      "sh",
      "-ec",
      "cd beskid_web_common && bun run --filter '@cyber-nomad-collective/spec-core' test",
    ])
    .withExec([
      "sh",
      "-ec",
      "cd site/platform-spec && bun install --frozen-lockfile",
    ])
    .withExec(["sh", "-ec", "cd site/platform-spec && bun run test"])
    .withExec([
      "sh",
      "-ec",
      "cd site/platform-spec && SKIP_ENV_VALIDATION=1 bun run build",
    ])
    .withExec([
      "sh",
      "-ec",
      "cd site/platform-spec && bun run verify:client-bundle",
    ])
    .stdout();
}

export async function platformSmoke(source: Directory): Promise<string> {
  let ctr = dag
    .container()
    .from(BUN_IMAGE)
    .withMountedDirectory("/src", source)
    .withWorkdir("/src");

  // The oven/bun image is Debian-based and ships without git, but platformSmoke
  // runs `git submodule update` and a `--require-git` metadata check below, which
  // otherwise fail with "git: not found" (exit 127). Install git first.
  ctr = ctr.withExec([
    "sh",
    "-ec",
    "apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*",
  ]);

  ctr = ctr
    .withExec(["sh", "-ec", "git submodule update --init beskid_web_common"])
    .withExec(["sh", "-ec", "bun install --frozen-lockfile"])
    .withExec(["sh", "-ec", "cd site/website && bun run prebuild"])
    .withExec([
      "sh",
      "-ec",
      "cd site/website && bun run verify:platform-spec-git-meta -- --require-git",
    ]);

  // Check root lockfile before smoke tests
  ctr = ctr.withExec([
    "sh",
    "-ec",
    [
      'if [ -f "package.json" ] && [ -f "bun.lock" ]; then',
      '  bun install --frozen-lockfile',
      'else',
      '  echo "skip root (no package.json or bun.lock)"',
      "fi",
    ].join("\n"),
  ]);

  const smoke = await ctr.stdout();
  return smoke;
}
