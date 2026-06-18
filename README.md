# Local Environments Setup Guide (Windows + WSL)

This guide explains how to run the local environment setup from this folder, including:

- First-run execution of `windows/bootstrap.ps1`
- Every interactive setup section inside the bootstrap script
- Running WSL Ansible setup stages via the `Makefile`
- Recommended flow for a brand-new laptop where tools are not yet installed

---

## 1. Recommended New Laptop Workflow (Azure DevOps ZIP)

If this is a fresh machine, the easiest bootstrapping path is:

1. In Azure DevOps (ADO), navigate to the [automation](https://dev.azure.com/softcat-data-services/_git/automation) repository.
2. Download the repo as ZIP.
3. Extract the ZIP to a local folder, for example:
   - `C:\automation`
4. Open **PowerShell** or **Windows Terminal**.
5. Navigate to this folder:
   - `cd "C:\automation\scripts\local environments"`
6. Run setup from terminal (see [section 5](#5-bootstrap-script-first-interactive-sections)).

Why this approach helps on a new laptop:

- You can start setup before Git is installed and configured.
- `bootstrap.ps1` can install missing tools (Git, VS Code, Azure CLI, Make, WSL, etc.) using Winget.
- You avoid any initial SSH/Git identity blockers.

---

## 2. Prerequisites

- OS: Windows 10/11.
- Run from **PowerShell**.
- Internet connection (Winget, WSL distro, apt/Ansible installs).
- Before running anything ensure you have requested admin rights for your user via the Admin Request Tool.
- Script self-elevates to admin when needed.

Optional but recommended before starting:

- Close apps that may block installs or restarts.
- Save your work (the SSH capability setup can trigger a restart).

---

## 3. Quick Start Commands

From this folder (`scripts/local environments`):

```powershell
make bootstrap
```

Then continue with WSL playbooks:

```powershell
make wsl-base WSL_USER=<your-linux-user>
make wsl-dev
make wsl-cloud
```

Example:

```powershell
make bootstrap WSL_DISTRO=Ubuntu-24.04
make wsl-base WSL_DISTRO=Ubuntu-24.04 WSL_USER=CollinM
make wsl-dev  WSL_DISTRO=Ubuntu-24.04
make wsl-cloud WSL_DISTRO=Ubuntu-24.04
```

---

## 4. Makefile Variables and Parameters

The `Makefile` passes values into scripts/commands.

- `WSL_DISTRO`
  - Default in `Makefile`: `Ubuntu-22.04`
  - Passed to `bootstrap.ps1` as `-WSL_DISTRO <value>`
- `WSL_USER`
  - Default in `Makefile`: `bantler`
  - Passed to Ansible base playbook as:
    - `-e wsl_default_user=<value>`

Important detail:

- `bootstrap.ps1` itself defaults to `Ubuntu-24.04`, but if you run via `make bootstrap`, the Makefile default (`Ubuntu-22.04`) is what gets passed unless overridden.

---

## 5. Bootstrap Script First (Interactive Sections)

Run either:

```powershell
make bootstrap
```

or directly (Run this if running on a new laptop):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\bootstrap.ps1 -WSL_DISTRO Ubuntu-24.04
```

The script asks you before each major section. Respond with `Y` (run) or `N` (skip).

### 5.1 Elevation and startup banner

What happens:

- Script checks for admin privileges.
- If not elevated, it relaunches itself as Administrator and exits the original process.

Typical terminal messages:

- `Requesting admin privileges...`
- `Running as Administrator`
- `Local Environment Bootstrap (Windows)`
- `Planned steps:`

### 5.2 Winget apps/install/upgrade section

Prompt:

- `Would you like to install Windows applications via Winget? (Y/N)`

If `Y`, the script does:

- `winget configure --Enable`
- `winget configure -f ./windows/configuration.dev.yaml`
- `winget upgrade --all --accept-source-agreements --accept-package-agreements`
- Adds `C:\Program Files (x86)\GnuWin32\bin` to user PATH (if missing)
- Copies profile/config files from `dotfiles`

Typical messages:

- `Enabling Winget configure`
- `Applying winget configuration`
- `Upgrading all packages`
- `Winget applications installed and configured successfully.`

Expected behavior on machines with existing tools:

- Winget may report packages as already installed/up-to-date.
- This is normal and still validates baseline tooling.

### 5.3 Git identity setup section

Prompt:

- `Would you like to configure Git user name and email? (Y/N)`

If `Y`, script behavior:

- Tries to read Office identity from registry.
- Falls back to manual prompts if values are not available.
- Runs:
  - `git config --global user.email <email>`
  - `git config --global user.name <name>`

Typical messages:

- `Setting Git email to ...`
- `Setting Git username to ...`
- `Git configuration applied successfully.`

### 5.4 SSH and OpenSSH setup section

Prompt:

- `Would you like to setup SSH keys and OpenSSH Client/Server capabilities? (Y/N)`

If `Y`, script behavior:

- Ensures Windows capabilities are installed:
  - `OpenSSH.Client~~~~0.0.1.0`
  - `OpenSSH.Server~~~~0.0.1.0`
- May request restart if capabilities were newly added.
- Starts/configures `sshd` and firewall rule.
- Creates keys in `%USERPROFILE%\.ssh`:
  - `id_ed25519`
  - `id_rsa` (4096-bit)
- Writes SSH config.
- Prints public keys to terminal.

Typical messages:

- `Checking and enabling OpenSSH Client and Server Windows Capabilities...`
- `Starting sshd service...`
- `Verifying Firewall rule for OpenSSH Server (sshd)...`
- `Generating ED25519 key...`
- `Generating RSA key (4096-bit)...`
- `Public keys:`
- `Please add the public key(s) to your GitHub and Azure DevOps accounts, or other git hosting provider...`
  - [Github](https://github.com/settings/keys) - Use `id_ed25519.pub` or `id_rsa.pub`
  - [Azure DevOps](https://dev.azure.com/softcat-data-services/-/user/keys) - Use `id_rsa.pub`

### 5.5 WSL install/bootstrap section

Prompt:

- `Would you like to install WSL '<distro>'? (Y/N)`

If `Y`, script behavior:

- Enables required Windows features:
  - `Microsoft-Windows-Subsystem-Linux`
  - `VirtualMachinePlatform`
- Sets WSL defaults and writes `%USERPROFILE%\.wslconfig`
- Installs distro if missing:
  - `wsl --install -d <WSL_DISTRO> --no-launch`
- Installs Ansible inside distro:
  - `apt-get update && apt-get install -y ansible`
- Attempts to copy this repository into WSL root path.

Typical messages:

- `Checking required Windows features are enabled...`
- `Setting WSL default version to 2`
- `Apply configuration for wslconfig`
- `Proceeding with installation of <distro>...`
- `<distro> installation completed successfully.`
- `Installing Ansible on <distro>...`
- `Ansible installed successfully on <distro>`

Final message:

- `Windows Bootstrap process completed! Ensure to restart your computer for all changes to take effect.`

---

## 6. Running Setup Stages with Makefile

After bootstrap, run the WSL configuration in stages.

### 6.1 Base setup

This stage configures the WSL distro with Ansible, setting up the default user and baseline Linux configuration.

```powershell
make wsl-base WSL_DISTRO=Ubuntu-24.04 WSL_USER=<your-linux-user>
```

What it runs:

- Executes inside WSL as root.
- Uses Ansible config from:
  - `scripts/local environments/wsl/ansible/ansible.cfg`
- Runs:
  - `playbooks/base.yaml`
- Passes variable:
  - `wsl_default_user=<WSL_USER>`

Typical output pattern:

- `PLAY [ ... ]`
- `TASK [ ... ]`
- `ok:` / `changed:` lines
- `PLAY RECAP`

### 6.2 Dev tools setup

This stage installs development tools and utilities inside the WSL distro. This should be specifically limited to tools and utilities that are required globally for development work.

```powershell
make wsl-dev WSL_DISTRO=Ubuntu-24.04
```

What it runs:

- Ansible playbook:
  - `playbooks/dev.yaml`

Typical output pattern:

- `PLAY ...`
- role/task execution for development tooling
- `PLAY RECAP`

### 6.3 Cloud tooling setup

This stage installs cloud-related tools and CLIs inside the WSL distro, such as Azure CLI, Terraform, etc.

```powershell
make wsl-cloud WSL_DISTRO=Ubuntu-24.04
```

What it runs:

- Ansible playbook:
  - `playbooks/cloud.yaml`

Typical output pattern:

- `PLAY ...`
- role/task execution for cloud tooling
- `PLAY RECAP`

---

## 7. Suggested End-to-End Order

1. `make bootstrap WSL_DISTRO=<your target distro>`
2. Reboot if prompted.
3. `make wsl-base WSL_DISTRO=<same distro> WSL_USER=<linux user>`
4. `make wsl-dev WSL_DISTRO=<same distro>`
5. `make wsl-cloud WSL_DISTRO=<same distro>`

This order ensures OS/tool prerequisites are available before playbooks run.

---

## 8. Common Notes and Troubleshooting

- If `make` is not found initially, run bootstrap directly first:
  - `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\bootstrap.ps1 -WSL_DISTRO Ubuntu-24.04`
- If script sections were skipped (`N`), rerun bootstrap and select `Y` for missed sections.
- If a section requests restart, restart before continuing.
- If WSL distro name does not match installed distros, list distros with:
  - `wsl --list --verbose`
- Keep `WSL_DISTRO` consistent across all commands.

---

## 9. Important Makefile Target Names

Use these targets from this folder:

- `bootstrap`
- `wsl-base`
- `wsl-dev`
- `wsl-cloud`

Note:

- The `help` target text currently mentions `win`, `wsl`, and `wsl-ansible`, but those target names are not defined in this Makefile. Use the target names listed above.
