export function info(message: string): void {
  console.error(`[INFO] beskid.ci: ${message}`);
}

export function warn(message: string): void {
  console.error(`[WARN] beskid.ci: ${message}`);
}

export function error(message: string): void {
  console.error(`[ERROR] beskid.ci: ${message}`);
}

export function fatal(message: string): never {
  error(message);
  throw new Error(message);
}
