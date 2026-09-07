# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Add a six-lane infrastructure contract that validates the canonical Coolify
  domains, OpenBao services, Compose profiles, rendered services, and release
  image identities.

### Changed

- Configure production and staging pckg with the Rust registry's canonical
  `PCKG_DATABASE_URL`, artifact, web-root, and bind-address settings; generate
  the URL from one percent-encoded PostgreSQL configuration source and remove
  obsolete .NET and legacy session settings.
- Keep pckg session authentication disabled until a trusted Coolify
  forward-auth boundary is configured.

### Fixed

- Derive each lane's Coolify service URLs from `config/domains.json` during
  manifest deployment, including the `learn` service, so the proxy receives
  the same immutable lane mapping as release smoke checks.
- Map the required `beskid-learn` image to an always-active production Compose
  service so immutable release manifests render and staging smoke checks can
  reach it after deployment.

### Removed

- Retire the standalone platform specification service, domain, volume,
  OpenBao path, and bootstrap configuration from the staging and production
  Coolify topology; the main site remains the sole public documentation
  surface.
