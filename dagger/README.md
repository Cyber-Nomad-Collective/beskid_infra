# Beskid CI (Dagger)

TypeScript Dagger module for Beskid aggregate and submodule CI. **All Dagger code lives here** (`beskid_infra/dagger/`).

The superrepo root [`dagger.json`](../../dagger.json) points at this directory.

## Prerequisites

- Docker (Dagger engine)
- [Dagger CLI](https://docs.dagger.io/install) matching [`.dagger-version`](.dagger-version)

```bash
cd beskid_infra/dagger
npm install
dagger functions
```

## Invoke from the superrepo root

```bash
dagger -m beskid_infra/dagger call corelib-gate --source=.
```

Or:

```bash
cd beskid_infra/dagger
dagger call corelib-gate --source=../..
```

## Objects and functions

| Object | Function | Role |
|--------|----------|------|
| `beskid-ci` | `compiler-rust-gate` | Parity + legacy-type guards, `cargo clippy`, workspace tests |
| `beskid-ci` | `lsp-command-contract-gate` | `beskid_lsp` + extension execute-command contract |
| `beskid-ci` | `corelib-gate` | Corelib manifest quality + `beskid test` (all targets) |
| `beskid-ci` | `vscode-gate` | `bun test` in `beskid_vscode` |
| `beskid-ci` | `open-vsx-publish` | Gates, LSP build, VSIX, Open VSX publish |
| `beskid-ci` | `platform-lockfile-gate` | `bun install --frozen-lockfile` per directory |
| `beskid-ci` | `site-build-gate` | Auth or platform-spec prebuild checks |
| `beskid-ci` | `platform-smoke` | Local/PR aggregate web smoke |
| `beskid-ci` | `bless-format-fixtures` | Regenerate format test fixtures |
| `beskid-ci` | `format-corpus-check` | Optional corelib format corpus check |
| `beskid-ci` | `compute-cli-version` | CLI/LSP semver |
| `compiler-release` | `compute-cli-version` | CLI/LSP semver (compiler-root `source`) |
| `compiler-release` | `build-cli-release` | Cross-target `beskid_cli` artifact |
| `compiler-release` | `build-lsp-release` | Cross-target `beskid_lsp` artifact |
| `compiler-release` | `publish-release-stream` | `gh release` for `cli-*` / `lsp-*` streams |
| `package-publish` | `publish-corelib` | Corelib workspace bundle → pckg |
| `package-publish` | `publish-templates` | Templates workspace (stub) |
| `versioning` | `commits-since-last-tag` | Commit count for `path` since latest matching tag |
| `versioning` | `version-from-tag-and-commit-count` | `MAJOR.MINOR.COUNT` (example `0.2.121`) |
| `versioning` | `nsv-next-version` | Conventional-commit next version (Daggerverse NSV) |
| `versioning` | `create-github-release` | Create release with `gh` CLI (Daggerverse GitHub module) |

## GitHub Actions example

```yaml
- uses: dagger/dagger-for-github@v8.4.1
  with:
    version: "0.21.0"
- run: npm ci
  working-directory: beskid_infra/dagger
- name: Corelib gate
  run: dagger -m beskid_infra/dagger call corelib-gate --source=.
```

Compiler-only jobs sparse-checkout this module from the [beskid](https://github.com/Cyber-Nomad-Collective/beskid) superrepo and call `compiler-release` with `--compiler-source=.` (compiler repo root).

## Secrets

| Variable | Used by |
|----------|---------|
| `OVSX_TOKEN` | `open-vsx-publish` |
| `COMPILER_SUBMODULE_TOKEN` | Submodule init (private compiler) |
| `BESKID_VSCODE_SUBMODULE_TOKEN` | Submodule init (private extension) |
| `BESKID_PCKG_API_KEY` | `package-publish.publish-corelib` |
| `GH_TOKEN` | `compiler-release.publish-release-stream`, `versioning.create-github-release` |
| `NODE_AUTH_TOKEN` | `site-build-gate` (GitHub Packages) |

## Daggerverse modules in use

- Rust helper: [`github.com/purpleclay/daggerverse/rust@225932120f3b39fcb8118c9aeb2e31f3c1b2d3f2`](https://daggerverse.dev/mod/github.com/purpleclay/daggerverse/rust@225932120f3b39fcb8118c9aeb2e31f3c1b2d3f2)
- Versioning helper: [`github.com/purpleclay/daggerverse/nsv@v0.12.2`](https://daggerverse.dev/mod/github.com/purpleclay/daggerverse/nsv)
- GitHub CLI helper: [`github.com/camptocamp/daggerverse/github@v0.1.5`](https://daggerverse.dev/mod/github.com/camptocamp/daggerverse/github)
