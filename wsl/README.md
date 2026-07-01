# WSL Ansible Guide

This folder contains the WSL provisioning layer for win-sible.

It uses Ansible playbooks to configure a Linux distro running in WSL with a staged approach:

- `base`: baseline WSL/Linux setup and shell/git/ssh configuration
- `dev`: developer tooling and Docker setup
- `cloud`: Azure and Databricks tooling setup

## What this folder does

Path: `wsl/ansible`

- Defines a local inventory (`inventory/local.ini`) targeting localhost.
- Uses `ansible.cfg` for local execution defaults.
- Organises setup into playbooks and reusable roles.
- Applies configuration idempotently where possible (safe to rerun).

### Playbooks

- `playbooks/base.yaml`
  - Roles: `wsl`, `common`, `shell`, `ssh`, `git`
  - Uses vars from `group_vars/all.yaml`
- `playbooks/dev.yaml`
  - Roles: `devtools`, `docker`
  - Uses vars from `group_vars/dev.yaml`
- `playbooks/cloud.yaml`
  - Role: `cloud`
  - Uses vars from `group_vars/cloud.yaml`

## What it currently supports

### 1) Base setup (`make wsl-base`)

WSL role (`roles/wsl`):

- Creates `/usr/sbin/policy-rc.d` to prevent auto-starting services during package installs.
- Detects and configures default Linux user (`wsl_default_user`).
- Creates user if needed, adds admin group membership, and can set password interactively.
- Writes `/etc/wsl.conf` with:
  - `systemd=true`
  - network host/resolver generation
  - interop enabled with Windows path append disabled
- Ensures per-user marker files like `.hushlogin`.

Common role (`roles/common`):

- Detects package manager and installs baseline packages from `group_vars/all.yaml` (`pkg_map`).
- Supports package manager mappings for:
  - `apt` (configured and active)
  - `pacman` and `apk` logic exists, but package lists are not currently defined in vars.
- On `apt`, adds Microsoft package feed and performs update/upgrade.

Shell role (`roles/shell`):

- Prompts to install/configure zsh.
- Prompts to install/configure Starship prompt.
- Creates shell modules for aliases/functions/starship/WSL helpers.
- Installs zsh plugins when zsh is selected.
- Copies starship config from repo dotfiles.

SSH role (`roles/ssh`):

- Detects Windows profile path and copies `%USERPROFILE%/.ssh` from Windows mount into WSL user `.ssh`.
- Applies secure ownership and permissions.
- Adds SSH agent bootstrap logic to user shell rc.

Git role (`roles/git`):

- Detects current global git identity.
- Prompts to update if already set.
- Sets `user.name` and `user.email` globally.

### 2) Dev setup (`make wsl-dev`)

Devtools role (`roles/devtools`):

- Installs dev packages from `group_vars/dev.yaml` (Python toolchain, Node.js/npm, PowerShell, jq, golang, etc.).
- Installs/sets up:
  - `tldr` via `pipx`
  - `eza`
  - `uv`
  - `tfenv` and pinned Terraform version
  - GitHub Copilot CLI
- Adds shell init blocks for zoxide, direnv, uv, Go, tfenv.
- Generates shell aliases module.

Docker role (`roles/docker`):

- Installs `docker.io` when `docker_enabled` is true.
- Adds execution user to `docker` group.

### 3) Cloud setup (`make wsl-cloud`)

Cloud role (`roles/cloud`):

- Installs Azure CLI.
- Adds Azure Databricks extension to Azure CLI.
- Installs Databricks CLI if missing.
- Generates `~/.databrickscfg` from template using `group_vars/cloud.yaml` profiles.

## Important variables and current defaults

From the repository `Makefile`:

- `WSL_DISTRO=Ubuntu-24.04`
- `WSL_USER=YourWSLUserNameHere`
- `WINDOWS_USER=%USERNAME%`
- `WSL_SIBLE_DIR=/root/.automation`

From WSL vars:

- `wsl_default_user: root` in `group_vars/all.yaml`
- `docker_enabled: true` in `group_vars/dev.yaml`
- Databricks profile hosts in `group_vars/cloud.yaml`

## How to run

Run commands from repository root on Windows PowerShell.

### Recommended sequence

```powershell
make wsl-rsync
make wsl-base
make wsl-dev
make wsl-cloud
```

### Individual stages

```powershell
make wsl-base
make wsl-dev
make wsl-cloud
```

### Override target distro/user

```powershell
make wsl-base WSL_DISTRO=Ubuntu-24.04 WSL_USER=<your-linux-user>
```

## Notes

- Playbooks run locally inside WSL against `localhost` with `become: true`.
- Some roles are interactive and will prompt for confirmation/input (shell, git, user password).
- If user/group membership changes (for example Docker group), open a new WSL session to apply group changes.
- Cloud setup writes `~/.databrickscfg`; review profile endpoints in `group_vars/cloud.yaml` before use.
