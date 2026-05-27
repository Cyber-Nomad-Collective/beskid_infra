#!/usr/bin/env bash
# Bundle VS Code extension and publish to Open VSX (port of ci/open_vsx.py).
set -euo pipefail

platform="${1:?platform}"
bin_name="${2:?bin_name}"
token="${3:?ovsx token}"

cd /src/beskid_vscode

previous_version=""
restore_version() {
  if [[ -n "$previous_version" ]]; then
    node -e "
const fs = require('node:fs');
const data = JSON.parse(fs.readFileSync('package.json', 'utf8'));
data.version = process.env.PREVIOUS_VERSION;
fs.writeFileSync('package.json', JSON.stringify(data, null, 2) + '\n');
" PREVIOUS_VERSION="$previous_version"
  fi
}
trap restore_version EXIT

icon="$(node -p "require('./package.json').icon || ''")"
if [[ -z "$icon" ]]; then
  echo "Missing \`icon\` in package.json" >&2
  exit 1
fi
if [[ ! -f "$icon" ]]; then
  echo "Extension icon file not found: $icon" >&2
  exit 1
fi
case "$icon" in
  *.svg|*.SVG)
    echo "Extension icon must be PNG/JPG for VSCE/Open VSX (found SVG): $icon" >&2
    exit 1
    ;;
esac

target=""
if target="$(/src/beskid_infra/dagger/scripts/resolve-extension-version.sh)"; then
  if [[ ! "$target" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]]; then
    echo "Derived extension version \`$target\` is not valid semver." >&2
    exit 1
  fi
else
  target=""
fi

if [[ -n "$target" ]]; then
  previous_version="$(node -p "require('./package.json').version")"
  current="$previous_version"
  if [[ "$current" == "$target" ]]; then
    echo "Open VSX: using extension version $current"
  else
    node -e "
const fs = require('node:fs');
const target = process.argv[1];
const path = 'package.json';
const data = JSON.parse(fs.readFileSync(path, 'utf8'));
const current = String(data.version ?? '').trim();
data.version = target;
fs.writeFileSync(path, JSON.stringify(data, null, 2) + '\n');
console.log('Open VSX: overriding extension version ' + current + ' -> ' + target);
" "$target"
  fi
fi

echo "Open VSX: bun install"
bun install --frozen-lockfile
echo "Open VSX: bun run build"
bun run build

publisher="$(node -p "require('./package.json').publisher")"
if [[ -z "$publisher" ]]; then
  echo "Missing \`publisher\` in package.json" >&2
  exit 1
fi

set +e
create_out="$(bunx ovsx create-namespace "$publisher" -p "$token" 2>&1)"
create_code=$?
set -e
if [[ "$create_code" -ne 0 ]]; then
  if ! printf '%s' "$create_out" | grep -qi 'already exists'; then
    echo "Open VS X namespace setup failed for publisher \`$publisher\`." >&2
    echo "$create_out" >&2
    exit 1
  fi
fi

mkdir -p dist
vsix="dist/beskid-${platform}.vsix"
echo "Open VSX: vsce package -> $vsix"
bunx @vscode/vsce package --target "$platform" --out "$vsix"

max_attempts=4
base_delay=3
for ((attempt = 1; attempt <= max_attempts; attempt++)); do
  set +e
  publish_out="$(bunx ovsx publish -p "$token" "$vsix" 2>&1)"
  publish_code=$?
  set -e
  if [[ "$publish_code" -eq 0 ]]; then
    if [[ "$attempt" -gt 1 ]]; then
      echo "Open VS X: publish succeeded on retry ${attempt}/${max_attempts}"
    fi
    exit 0
  fi
  if [[ "$attempt" -lt "$max_attempts" ]] && printf '%s' "$publish_out" | grep -Eiq '(status 50[0-9]|bad gateway|gateway timeout|timed out|econnreset|econnrefused|service unavailable)'; then
    delay=$((base_delay * (2 ** (attempt - 1))))
    echo "Open VSX: publish attempt ${attempt}/${max_attempts} failed with transient error; retrying in ${delay}s..." >&2
    sleep "$delay"
    continue
  fi
  echo "Open VS X: publish failed after ${attempt} attempt(s). Output follows." >&2
  echo "$publish_out" >&2
  exit 1
done
