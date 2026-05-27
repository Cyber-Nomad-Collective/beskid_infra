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
dagger -m beskid_infra/dagger call open-vsx-publish \
  --source=. \
  --platform=linux-x64 \
  --bin-name=beskid_lsp
```

Or:

```bash
cd beskid_infra/dagger
dagger call open-vsx-publish --source=../.. --platform=linux-x64 --bin-name=beskid_lsp
```

## Objects and functions

| Object | Function | Role |
|--------|----------|------|
| `beskid-ci` | `compiler-rust-gate` | `cargo clippy` + `cargo test --workspace` |
| `beskid-ci` | `vscode-gate` | `bun test` in `beskid_vscode` |
| `beskid-ci` | `open-vsx-publish` | Gates, LSP build, VSIX, Open VSX publish |
| `compiler-release` | `compute-cli-version` | CLI/LSP semver |
| `compiler-release` | `build-cli-release` | Cross-target `beskid_cli` artifact |
| `compiler-release` | `build-lsp-release` | Cross-target `beskid_lsp` artifact |
| `package-publish` | `publish-corelib` | pckg workspace publish |
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
- name: Open VSX
  env:
    OVSX_TOKEN: ${{ secrets.OVSX_TOKEN }}
  run: |
    dagger -m beskid_infra/dagger call open-vsx-publish \
      --source=. \
      --platform=linux-x64 \
      --bin-name=beskid_lsp
```

Compiler-only jobs sparse-checkout this module from the [beskid](https://github.com/Cyber-Nomad-Collective/beskid) superrepo and call `compiler-release` with `--compiler-source=.` (compiler repo root).

## Secrets

| Variable | Used by |
|----------|---------|
| `OVSX_TOKEN` | `open-vsx-publish` |
| `COMPILER_SUBMODULE_TOKEN` | Submodule init (private compiler) |
| `BESKID_VSCODE_SUBMODULE_TOKEN` | Submodule init (private extension) |
| `BESKID_PCKG_API_KEY` | `package-publish` (`--pckg-api-key=env:BESKID_PCKG_API_KEY`) |
| `GH_TOKEN` | `versioning.create-github-release` |

## Daggerverse modules in use

- Rust helper: [`github.com/purpleclay/daggerverse/rust@225932120f3b39fcb8118c9aeb2e31f3c1b2d3f2`](https://daggerverse.dev/mod/github.com/purpleclay/daggerverse/rust@225932120f3b39fcb8118c9aeb2e31f3c1b2d3f2)
- Versioning helper: [`github.com/purpleclay/daggerverse/nsv@v0.12.2`](https://daggerverse.dev/mod/github.com/purpleclay/daggerverse/nsv)
- GitHub CLI helper: [`github.com/camptocamp/daggerverse/github@v0.1.5`](https://daggerverse.dev/mod/github.com/camptocamp/daggerverse/github)

Other useful modules you can adopt later:
- Conventional-commit semver for monorepos: [`github.com/telchak/daggerverse/semver@v0.2.0`](https://daggerverse.dev/mod/github.com/telchak/daggerverse/semver)
- Release metadata lookup: [`github.com/jedevc/daggerverse/github-release@v1.0.0`](https://daggerverse.dev/mod/github.com/jedevc/daggerverse/github-release)
