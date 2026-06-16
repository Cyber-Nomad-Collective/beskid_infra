import { type Directory } from "@dagger.io/dagger";

import {
  REQUIRED_FILES,
  WORKSPACE_MEMBERS,
  discoverProjectManifest,
  memberPackageMap,
  projectField,
  resolveCorelibRoot,
} from "./lib/corelib-manifest.js";

export async function corelibQuality(source: Directory): Promise<string> {
  const root = await resolveCorelibRoot(source);
  const corelib = root.directory("beskid_corelib");

  try {
    await corelib.entries();
  } catch {
    throw new Error("Missing corelib package directory: beskid_corelib");
  }

  const manifestName = await discoverProjectManifest(corelib);
  const manifest = await corelib.file(manifestName).contents();

  const name = projectField(manifest, "name");
  if (name !== "corelib") {
    throw new Error(`Project name must be corelib, got: ${name ?? "null"}`);
  }

  const projectType = projectField(manifest, "type");
  if (projectType !== "Aggregate") {
    throw new Error(
      `Aggregate corelib manifest must set type = Aggregate, got: ${projectType ?? "null"}`,
    );
  }

  const version = projectField(manifest, "version");
  if (!version) {
    throw new Error(`${manifestName} is missing version`);
  }

  let workspaceText: string;
  try {
    workspaceText = await root.file("CoreLib.bws").contents();
  } catch {
    throw new Error("Missing workspace manifest: CoreLib.bws");
  }

  if (projectField(workspaceText, "name") !== "corelib") {
    throw new Error("CoreLib.bws workspace name must be corelib");
  }

  const memberPackages = memberPackageMap(workspaceText);
  if (memberPackages.size === 0) {
    throw new Error("CoreLib.bws must declare member blocks with package keys");
  }

  for (const [registryName, sourceRel] of WORKSPACE_MEMBERS) {
    const memberDir = root.directory(sourceRel);
    const memberManifestName = await discoverProjectManifest(memberDir);
    const memberManifest = await memberDir
      .file(memberManifestName)
      .contents();
    const memberName = projectField(memberManifest, "name");
    if (memberName !== registryName) {
      throw new Error(
        `${memberManifestName}: project.name must be ${registryName}, got ${memberName ?? "null"}`,
      );
    }

    const hasReadme =
      (await fileExists(memberDir, "README.md")) ||
      (await fileExists(memberDir, "readme.md"));
    if (!hasReadme) {
      throw new Error(`Missing member README for ${registryName}`);
    }

    if (!memberPackages.has(registryName)) {
      throw new Error(
        `CoreLib.bws is missing a member entry for registry package ${registryName}`,
      );
    }
  }

  for (const rel of REQUIRED_FILES) {
    try {
      await root.file(rel).contents();
    } catch {
      throw new Error(`Missing required file: ${rel}`);
    }
  }

  return `quality OK: corelib workspace manifest version ${version}`;
}

async function fileExists(dir: Directory, name: string): Promise<boolean> {
  try {
    await dir.file(name).contents();
    return true;
  } catch {
    return false;
  }
}
