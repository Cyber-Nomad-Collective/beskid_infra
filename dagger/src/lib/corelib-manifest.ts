import { type Directory } from "@dagger.io/dagger";

import { resolveCompilerTree } from "../gates.js";

export const WORKSPACE_MEMBERS: ReadonlyArray<readonly [string, string]> = [
  ["corelib", "beskid_corelib"],
  ["corelib_foundation", "packages/foundation"],
  ["corelib_runtime", "packages/runtime"],
  ["corelib_compiler_sdk", "packages/compiler-sdk"],
  ["corelib_console", "packages/console"],
  ["corelib_concurrency", "packages/concurrency"],
];

export const REQUIRED_FILES = [
  "packages/foundation/src/Core/Results/Results.bd",
  "packages/foundation/.generated/Core/Text/Regex/Generated.g.bd",
  "packages/foundation/src/Core/ErrorHandling/ErrorHandling.bd",
  "packages/foundation/src/Core/String/String.bd",
  "packages/foundation/src/Core/Optional/Option.bd",
  "packages/foundation/src/Collections/Collections.bd",
  "packages/foundation/src/Collections/Array.bd",
  "packages/foundation/src/Query/Query.bd",
  "packages/foundation/src/Query/QueryState.bd",
  "packages/foundation/src/Testing/Testing.bd",
  "packages/foundation/src/Testing/Assert.bd",
  "packages/foundation/src/Testing/Contracts.bd",
  "packages/foundation/src/Core/Input/Input.bd",
  "packages/foundation/src/Core/Output/Output.bd",
  "packages/foundation/src/Core/Syscall/Syscall.bd",
];

const MEMBER_BLOCK_RE = /member\s+"([^"]+)"\s*\{([^}]*)\}/gs;

export function projectField(content: string, key: string): string | null {
  for (const line of content.split("\n")) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#") || !trimmed.includes("=")) {
      continue;
    }
    const eq = trimmed.indexOf("=");
    const currentKey = trimmed.slice(0, eq).trim();
    if (currentKey === key) {
      return trimmed
        .slice(eq + 1)
        .trim()
        .replace(/^"/, "")
        .replace(/"$/, "");
    }
  }
  return null;
}

export function memberPackageMap(workspaceText: string): Map<string, string> {
  const packages = new Map<string, string>();
  for (const match of workspaceText.matchAll(MEMBER_BLOCK_RE)) {
    const body = match[2] ?? "";
    const pkg = projectField(body, "package");
    if (pkg) {
      packages.set(pkg, projectField(body, "path") ?? "");
    }
  }
  return packages;
}

export async function resolveCorelibRoot(
  source: Directory,
): Promise<Directory> {
  try {
    await source.file("CoreLib.bws").contents();
    return source;
  } catch {
    // Not a corelib workspace root.
  }
  const compiler = await resolveCompilerTree(source);
  try {
    await compiler.file("corelib/CoreLib.bws").contents();
    return compiler.directory("corelib");
  } catch {
    try {
      await compiler.file("CoreLib.bws").contents();
      return compiler;
    } catch {
      throw new Error(
        "source must be superrepo root, compiler workspace, or corelib workspace root",
      );
    }
  }
}

export async function discoverProjectManifest(
  projectDir: Directory,
): Promise<string> {
  const entries = await projectDir.entries();
  const bproj = entries
    .filter((e) => e.endsWith(".bproj"))
    .sort((a, b) => a.localeCompare(b));
  if (bproj.length !== 1) {
    throw new Error(
      `Expected exactly one .bproj in project directory, found ${bproj.length}`,
    );
  }
  return bproj[0]!;
}
