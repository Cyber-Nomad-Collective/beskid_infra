import { dag, type Container, type Directory } from "@dagger.io/dagger";

import { envOrEmpty, withSecrets } from "./env.js";

function gitContainer(source: Directory): Container {
  return withSecrets(
    dag
      .container()
      .from("alpine/git:latest")
      .withDirectory("/src", source)
      .withWorkdir("/src")
      .withEnvVariable("GIT_TERMINAL_PROMPT", "0"),
    [
      "COMPILER_SUBMODULE_TOKEN",
      "BESKID_VSCODE_SUBMODULE_TOKEN",
      "PCKG_SUBMODULE_TOKEN",
    ],
  );
}

function compilerSubmoduleUrl(): string {
  const token = envOrEmpty("COMPILER_SUBMODULE_TOKEN");
  if (token) {
    return `https://x-access-token:${token}@github.com/Cyber-Nomad-Collective/beskid_compiler.git`;
  }
  return (
    envOrEmpty("COMPILER_SUBMODULE_URL") ||
    "https://github.com/Cyber-Nomad-Collective/beskid_compiler.git"
  );
}

function vscodeSubmoduleUrl(): string {
  const token = envOrEmpty("BESKID_VSCODE_SUBMODULE_TOKEN");
  if (token) {
    return `https://x-access-token:${token}@github.com/Cyber-Nomad-Collective/beskid_vscode.git`;
  }
  return (
    envOrEmpty("BESKID_VSCODE_SUBMODULE_URL") ||
    "https://github.com/Cyber-Nomad-Collective/beskid_vscode.git"
  );
}

export async function initCompilerSubmodule(
  source: Directory,
): Promise<Directory> {
  const url = compilerSubmoduleUrl();
  return gitContainer(source)
    .withExec(["git", "submodule", "sync", "--", "compiler"])
    .withExec([
      "git",
      "config",
      "submodule.compiler.url",
      url,
    ])
    .withExec([
      "git",
      "-c",
      "protocol.version=2",
      "submodule",
      "update",
      "--init",
      "--recursive",
      "--depth",
      "1",
      "compiler",
    ])
    .directory("/src");
}

export async function initBeskidVscodeSubmodule(
  source: Directory,
): Promise<Directory> {
  const url = vscodeSubmoduleUrl();
  return gitContainer(source)
    .withExec(["git", "submodule", "sync", "--", "beskid_vscode"])
    .withExec([
      "git",
      "config",
      "submodule.beskid_vscode.url",
      url,
    ])
    .withExec([
      "git",
      "-c",
      "protocol.version=2",
      "submodule",
      "update",
      "--init",
      "--depth",
      "1",
      "beskid_vscode",
    ])
    .directory("/src");
}
