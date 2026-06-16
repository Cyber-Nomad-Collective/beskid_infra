import { dag, type Directory } from "@dagger.io/dagger";

const BUN_IMAGE = "oven/bun:1.2";

const DEFAULT_LOCKFILE_DIRS = [
  ".",
  "beskid_tracker",
  "site/auth",
  "beskid_nexus/gitnexus",
  "beskid_nexus/gitnexus-web",
];

export async function platformLockfileGate(
  source: Directory,
  dirs: string[] = [],
): Promise<string> {
  const targets = dirs.length > 0 ? dirs : DEFAULT_LOCKFILE_DIRS;
  let ctr = dag
    .container()
    .from(BUN_IMAGE)
    .withMountedDirectory("/src", source)
    .withWorkdir("/src");

  const lines = [
    "set -e",
    ...targets.map((dir) => {
      const safe = dir.replace(/"/g, '\\"');
      return [
        `if [ -f "${safe}/package.json" ] && [ -f "${safe}/bun.lock" ]; then`,
        `  echo "==> verify frozen lockfile: ${safe}"`,
        `  (cd "${safe}" && bun install --frozen-lockfile >/dev/null)`,
        `else`,
        `  echo "skip ${safe} (no package.json or bun.lock)"`,
        `fi`,
      ].join("\n");
    }),
    'echo "All lockfiles match package.json"',
  ];

  return ctr.withExec(["sh", "-ec", lines.join("\n")]).stdout();
}

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

  const lockfile = await platformLockfileGate(source, ["."]);

  ctr = ctr
    .withExec(["sh", "-ec", "git submodule update --init beskid_web_common"])
    .withExec(["sh", "-ec", "bun install --frozen-lockfile"])
    .withExec(["sh", "-ec", "cd site/website && bun run prebuild"])
    .withExec([
      "sh",
      "-ec",
      "cd site/website && bun run verify:platform-spec-git-meta -- --require-git",
    ]);

  const smoke = await ctr.stdout();
  return `${lockfile}\n${smoke}`;
}
