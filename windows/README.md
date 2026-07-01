# Windows Bootstrap Guide

This folder contains the Windows bootstrap entrypoint and WinGet configuration files used to set up a developer machine.

## What the bootstrap script does

The script `bootstrap.ps1` is an interactive Windows setup tool. It:

- Verifies it is running on Windows.
- Self-elevates to Administrator if needed.
- Shows an interactive menu for setup tasks.

### Main menu options

1. Install developer applications via WinGet
- Runs `winget configure --Enable`.
- Applies `configuration.dev.yaml` with `winget configure`.
- Runs `winget upgrade --all`.
- Adds `C:\Program Files (x86)\GnuWin32\bin` to the user PATH (if missing).
- Copies repo dotfiles into:
  - `%USERPROFILE%\.config`
  - `%USERPROFILE%\Documents\PowerShell`

2. Enable OpenSSH and setup SSH keys
- Installs/enables Windows OpenSSH Client and Server capabilities.
- Starts/configures `sshd` service and firewall rule for port 22.
- Generates SSH keys in `%USERPROFILE%\.ssh`:
  - `id_ed25519`
  - `id_rsa` (4096-bit)
- Creates SSH config file `%USERPROFILE%\.ssh\config`.
- Starts/enables the `ssh-agent` service.

3. Apply Git global identity
- Sets `git config --global user.email`.
- Sets `git config --global user.name`.
- Attempts to read values from Office identity registry first; prompts if unavailable.

4. Install and configure WSL
- Enables required Windows features:
  - `Microsoft-Windows-Subsystem-Linux`
  - `VirtualMachinePlatform`
- Sets WSL default version to 2.
- Writes `%USERPROFILE%\.wslconfig` with mirrored networking options.
- Installs selected distro (default: `Ubuntu-24.04`) if not already installed.
- Installs `ansible` and `rsync` inside WSL.
- Syncs this repo into WSL at `/root/.automation` using `rsync`.

WSL submenu also includes unregistering the selected distro.

## Files in this folder

- `bootstrap.ps1`: interactive Windows bootstrap script.
- `configuration.dev.yaml`: WinGet configuration for development apps.
- `configuration.gaming.yaml`: optional WinGet configuration for gaming-related apps.

## How to run the bootstrap

From the repository root on Windows PowerShell:

```powershell
make bootstrap
```

Or run the script directly:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\bootstrap.ps1
```

To choose a specific distro name (example):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\bootstrap.ps1 -WSL_DISTRO "Ubuntu-24.04"
```

## Notes

- The script is interactive; choose menu options as needed.
- Several actions require a reboot to fully apply changes.
- After SSH key generation, add your public key(s) to your git hosting provider.
