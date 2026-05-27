import { dag, type Secret } from "@dagger.io/dagger";

import { fatal } from "./log.js";

export function envOrEmpty(name: string): string {
  return (process.env[name] ?? "").trim();
}

export function requireEnv(name: string): string {
  const value = envOrEmpty(name);
  if (!value) {
    fatal(`Missing required environment variable: ${name}`);
  }
  return value;
}

export function secretFromEnv(name: string): Secret | undefined {
  const value = envOrEmpty(name);
  if (!value) {
    return undefined;
  }
  return dag.setSecret(name, value);
}

export function withSecrets(
  ctr: ReturnType<typeof dag.container>,
  names: string[],
): ReturnType<typeof dag.container> {
  let next = ctr;
  for (const name of names) {
    const secret = secretFromEnv(name);
    if (secret) {
      next = next.withSecretVariable(name, secret);
    }
  }
  return next;
}
