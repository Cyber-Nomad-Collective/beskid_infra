# Ansible: bootstrap Coolify host

This directory contains an **idempotent** playbook that prepares a Linux server to run Coolify and accept later OpenTofu-driven configuration.

## What it does

- Installs base packages (`curl`, `git`, `jq`, …)
- Configures firewall (UFW on Debian/Ubuntu)
- Opens ports **22, 80, 443, 8000**
- Disables swap (Coolify best practice)
- Installs Docker (only if missing)
- **Detects Coolify** (checks `/data/coolify` and existing containers)
- Optionally installs Coolify (disabled by default)

## Run

```bash
cd beskid_infra

cp ansible/inventory/hosts.ini.example ansible/inventory/hosts.ini
# edit hosts.ini

ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/prepare-opentofu-host.yml
```

## Install Coolify

By default, `coolify_install: false`. To allow installation:

```bash
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/prepare-opentofu-host.yml \
  -e coolify_install=true
```

Coolify installer script: `https://cdn.coollabs.io/coolify/install.sh` (used when `coolify_install=true`).

## Notes

- This playbook focuses on bootstrapping the host. It does **not** configure Coolify apps/domains; that is done via OpenTofu (`beskid_infra/environments/*`).
