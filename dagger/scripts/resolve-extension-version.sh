#!/usr/bin/env bash
# Resolve extension semver from git tags / GITHUB_*.
set -euo pipefail

ref_name="${GITHUB_REF_NAME:-}"
ref_type="${GITHUB_REF_TYPE:-}"

if [[ "$ref_type" == "tag" ]] && [[ "$ref_name" =~ ^v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
  printf '%s' "${ref_name#v}"
  exit 0
fi

latest_tag="$(git describe --tags --abbrev=0 --match 'v[0-9]*.[0-9]*.[0-9]*')"
if [[ ! "$latest_tag" =~ ^v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
  echo "Tag \`${latest_tag}\` is not semver (expected vMAJOR.MINOR.PATCH)" >&2
  exit 1
fi

major="${BASH_REMATCH[1]}"
minor="${BASH_REMATCH[2]}"
patch="${BASH_REMATCH[3]}"
commits_since="$(git rev-list --count "${latest_tag}..HEAD")"

if [[ "$commits_since" -le 0 ]]; then
  printf '%s.%s.%s' "$major" "$minor" "$patch"
else
  printf '%s.%s.%s' "$major" "$minor" "$((patch + commits_since))"
fi
