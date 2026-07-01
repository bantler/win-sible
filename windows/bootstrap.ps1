[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$WSL_DISTRO = "Ubuntu-24.04"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Check if script is running on Windows
if (-not ($env:OS -eq "Windows_NT")) {
    throw "This script must be run on Windows."
}

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-PropertyIfExists {
    param(
        [Parameter(Mandatory = $false)]
        [object]$Object,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName
    )

    if ($null -eq $Object) {
        return $null
    }

    $property = $Object.PSObject.Properties[$PropertyName]
    if ($null -ne $property) {
        return $property.Value
    }

    return $null
}

if (-not (Test-Admin)) {
    Write-Host "Requesting admin privileges..."

    $elevationArgs = @(
        "-NoProfile"
        "-ExecutionPolicy Bypass"
        "-File `"$PSCommandPath`""
        "-WSL_DISTRO `"$WSL_DISTRO`""
    ) -join ' '

    Start-Process powershell.exe -Verb RunAs -WorkingDirectory (Split-Path -Parent $PSCommandPath) -ArgumentList $elevationArgs | Out-Null

    # CRITICAL: hard exit so Make doesn't hang and no duplicate logic runs
    exit 0
}

# Set script directory to the repository root for any relative file operations. This ensures consistent behavior regardless of how the script is launched.
$scriptDir = Split-Path -Parent $PSCommandPath

function Show-MainMenu {
    Clear-Host
    Write-Host "Running as Administrator" -ForegroundColor Green
    Write-Host "" 
    Write-Host "========================================================" -ForegroundColor DarkCyan
    Write-Host "         Local Environment Bootstrap (Windows)" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor DarkCyan
    Write-Host "" 
    Write-Host "1. Install Developer Applications via Winget." -ForegroundColor Gray
    Write-Host "2. Enable OpenSSH capabilities and setup SSH keys." -ForegroundColor Gray
    Write-Host "3. Apply Git configuration (email and username)." -ForegroundColor Gray
    Write-Host "4. Install Windows Subsystem for Linux (WSL)." -ForegroundColor Gray
    Write-Host "Q. Quit" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "Select an option"

    switch ($choice) {
        '1' { Show-WingetMenu }
        '2' { Show-OpenSSHMenu }
        '3' { Show-GitConfigMenu }
        '4' { Show-WSLMenu }
        'Q' { return }
        default { 
            Write-Host "Warning: Invalid selection '$choice'. Please select a valid option (1, 2, 3, 4, or Q)." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            Show-MainMenu 
        }
    }
}

function Show-WingetMenu {
    Clear-Host
    Write-Host "Running as Administrator" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor DarkCyan
    Write-Host "             Winget Application Management" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor DarkCyan
    Write-Host "1. Apply Winget Configuration" -ForegroundColor Gray
    Write-Host "2. Upgrade all Installed Packages" -ForegroundColor Gray
    Write-Host "B. Back" -ForegroundColor Gray

    $choice = Read-Host "Select an option"

    switch ($choice) {
        '1' { Apply-WingetConfiguration }
        '2' { Upgrade-AllWingetPackages }
        'B' { Show-MainMenu }
        default { 
            Write-Host "Warning: Invalid selection '$choice'. Please select a valid option (1, 2, or B)." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            Show-WingetMenu
        }
    }
}

function Apply-WingetConfiguration {

    Write-Host ""
    Write-Host "Enabling Winget configure" -ForegroundColor Cyan
    winget configure --Enable

    Write-Host "Applying winget configuration" -ForegroundColor Cyan
    winget configure -f "$scriptDir\configuration.dev.yaml" --accept-configuration-agreements

    Write-Host "Upgrading all packages" -ForegroundColor Cyan
    winget upgrade --all --accept-package-agreements --accept-source-agreements

    # Add GnuWin32 to user PATH if not already present
    $pathToAdd = "C:\Program Files (x86)\GnuWin32\bin"
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")

    if ($userPath -notlike "*$pathToAdd*") {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$pathToAdd", "User")
    }

    # Copy dotfiles to user profile
    $dotfilesSource = Join-Path $scriptDir "../dotfiles\.config"
    $dotfilesDestination = Join-Path $env:USERPROFILE ".config"

    if (Test-Path $dotfilesSource) {
        Write-Host "Copying dotfiles from $dotfilesSource to $dotfilesDestination" -ForegroundColor Cyan
        Copy-Item -Path $dotfilesSource -Destination $dotfilesDestination -Recurse -Force
    } else {
        Write-Host "Dotfiles source not found: $dotfilesSource" -ForegroundColor Yellow
    }

    # Copy dotfiles to user profile
    $dotfilesSource = Join-Path $scriptDir "../dotfiles\.pwsh\*"
    $dotfilesDestination = Join-Path $env:USERPROFILE "Documents\PowerShell"

    if (Test-Path $dotfilesSource) {
        Write-Host "Copying dotfiles from $dotfilesSource to $dotfilesDestination" -ForegroundColor Cyan
        Copy-Item -Path $dotfilesSource -Destination $dotfilesDestination -Recurse -Force
    } else {
        Write-Host "Dotfiles source not found: $dotfilesSource" -ForegroundColor Yellow
    }

    Write-Host "Winget configuration applied successfully. Recommended to restart your computer to ensure all changes take effect." -ForegroundColor Green

    Pause
    Show-WingetMenu
}

function Upgrade-AllWingetPackages {

    Write-Host ""
    Write-Host "Upgrading all installed packages via Winget..." -ForegroundColor Cyan
    winget upgrade --all --accept-package-agreements --accept-source-agreements

    Write-Host "All packages upgraded successfully." -ForegroundColor Green
    
    Pause
    Show-WingetMenu
}

function Show-OpenSSHMenu {
    Clear-Host
    Write-Host "Running as Administrator" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor DarkCyan
    Write-Host "             OpenSSH Configuration" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor DarkCyan
    Write-Host "1. Enable OpenSSH Client and Server Capabilities" -ForegroundColor Gray
    Write-Host "2. Generate SSH Keys and Configure SSH Agent" -ForegroundColor Gray
    Write-Host "B. Back" -ForegroundColor Gray

    $choice = Read-Host "Select an option"

    switch ($choice) {
        '1' { Enable-OpenSSHCapabilities }
        '2' { Setup-SSHKeys }
        'B' { Show-MainMenu }
        default { 
            Write-Host "Warning: Invalid selection '$choice'. Please select a valid option (1, 2, or B)." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            Show-OpenSSHMenu
        }
    }
}

function Enable-OpenSSHCapabilities {

    Write-Host ""

    # Check and enable required Windows optional features.
    Write-Host "Checking and enabling OpenSSH Client and Server Windows Capabilities if not already enabled..." -ForegroundColor Cyan

    $requiredCapabilities = @(
        "OpenSSH.Client~~~~0.0.1.0",
        "OpenSSH.Server~~~~0.0.1.0"
    )
        
    foreach ($capabilityName in $requiredCapabilities) {
        $capability = Get-WindowsCapability -Online -Name $capabilityName

        if ($capability.State -eq "Enabled") {
            Write-Host "$capabilityName is already enabled" -ForegroundColor Yellow
        }
        else {
            Write-Host "$capabilityName is not enabled. Enabling now..." -ForegroundColor Green
            dism.exe /online /Add-Capability /CapabilityName:$capabilityName /norestart
        }
    }

    # Start the sshd service
    Write-Host "Checking sshd service status..." -ForegroundColor Cyan
    $sshdService = Get-Service -Name sshd
    if ($sshdService.Status -eq "Running") {
        Write-Host "sshd service is already running" -ForegroundColor Yellow
    }
    else {
        Write-Host "Starting sshd service..." -ForegroundColor Green
        Start-Service sshd
        Write-Host "Setting sshd service to start automatically on boot..." -ForegroundColor Green
        Set-Service -Name sshd -StartupType 'Automatic'
    }

    # Confirm the Firewall rule is configured. It should be created automatically by setup. Run the following to verify
    Write-Host "Verifying Firewall rule for OpenSSH Server (sshd)..." -ForegroundColor Cyan
    if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {
        Write-Host "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..." -ForegroundColor Green
        New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    } else {
        Write-Host "Firewall rule 'OpenSSH-Server-In-TCP' already exists." -ForegroundColor Yellow
    }

    Write-Host "OpenSSH Client and Server capabilities enabled successfully. Recommended to restart your computer to ensure all changes take effect." -ForegroundColor Green
    Pause
    Show-OpenSSHMenu
}

function Setup-SSHKeys {

    Write-Host ""

    # Ensure .ssh directory exists
    $KeyPath = Join-Path $env:USERPROFILE ".ssh"
    if (-not (Test-Path $KeyPath)) {
        New-Item -ItemType Directory -Path $KeyPath | Out-Null
    }

    # Elevated 32-bit and 64-bit sessions can resolve Windows folders differently.
    $sshKeygenCandidates = @(
        (Join-Path $env:WINDIR "System32\OpenSSH\ssh-keygen.exe"),
        (Join-Path $env:WINDIR "Sysnative\OpenSSH\ssh-keygen.exe")
    )

    $sshKeygenPath = $sshKeygenCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $sshKeygenPath) {
        $sshKeygenCommand = Get-Command ssh-keygen -ErrorAction SilentlyContinue
        if ($sshKeygenCommand -and (Test-Path $sshKeygenCommand.Source)) {
            $sshKeygenPath = $sshKeygenCommand.Source
        }
    }

    if (-not $sshKeygenPath) {
        $triedLocations = $sshKeygenCandidates -join ", "
        throw "Unable to find ssh-keygen.exe in this elevated session. Checked: $triedLocations"
    }

    Write-Host "Creating SSH keys in $KeyPath" -ForegroundColor Cyan

    # Get email for current user
    $identity = Get-ItemProperty "HKCU:\Software\Microsoft\Office\16.0\Common\Identity" -ErrorAction SilentlyContinue
    $Email = Get-PropertyIfExists -Object $identity -PropertyName "ADUserName"
    if (-not $Email) {
        $Email = Read-Host "Enter your email address"
    }

    # ED25519 KEY
    $ed25519Path = Join-Path $KeyPath "id_ed25519"
    Write-Host "Generating ED25519 key..." -ForegroundColor Green
    & $sshKeygenPath -t ed25519 -C $Email -f $ed25519Path

    # RSA KEY
    $rsaPath = Join-Path $KeyPath "id_rsa"
    Write-Host "Generating RSA key (4096-bit)..." -ForegroundColor Green
    & $sshKeygenPath -t rsa -b 4096 -C $Email -f $rsaPath

    # Start SSH agent
    Write-Host "Starting SSH agent..." -ForegroundColor Cyan
    Start-Service ssh-agent -ErrorAction SilentlyContinue
    Set-Service ssh-agent -StartupType Automatic

    # Create SSH config
    $configPath = Join-Path $KeyPath "config"

    $sshHosts = @(
        @{ Comment = "Default GitHub key"; Host = "github.com"; HostName = "github.com"; IdentityFile = "~/.ssh/id_ed25519"; User = "git" }
        @{ Comment = "Azure / generic servers"; Host = "azure-*"; User = "azureuser"; IdentityFile = "~/.ssh/id_rsa" }
        @{ Host = "*"; AddKeysToAgent = "yes"; IdentitiesOnly = "yes" }
    )

    $configContent = @()
    foreach ($hostConfig in $sshHosts) {
        if ($hostConfig.ContainsKey("Comment") -and $hostConfig["Comment"]) {
            $configContent += "# $($hostConfig["Comment"])"
        }
        $configContent += "Host $($hostConfig["Host"])"
        $hostConfig.GetEnumerator() | Where-Object { $_.Key -notin @("Comment", "Host") } | ForEach-Object {
            $configContent += "$($_.Key) $($_.Value)"
        }
        $configContent += ""
    }

    $configText = $configContent -join "`n"
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($configPath, $configText, $utf8NoBom)

    Write-Host "SSH config created" -ForegroundColor Green

    # Output public keys
    Write-Host "Public keys:" -ForegroundColor Cyan
    Get-Content "$ed25519Path.pub"
    Get-Content "$rsaPath.pub"

    Write-Host "SSH environment is now configured..." -ForegroundColor Green
    Write-Host "Please add the public key(s) to your GitHub account, Azure DevOps - RSA, or other git hosting provider to enable SSH authentication." -ForegroundColor Cyan

    Pause
    Show-OpenSSHMenu
}

function Show-GitConfigMenu {
    Clear-Host
    Write-Host "Running as Administrator" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor DarkCyan
    Write-Host "                 Git Configuration" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor DarkCyan
    Write-Host "1. Configure Git user name and email" -ForegroundColor Gray
    Write-Host "B. Back" -ForegroundColor Gray

    $choice = Read-Host "Select an option"

    switch ($choice) {
        '1' { Configure-GitIdentity }
        'B' { Show-MainMenu }
        default { 
            Write-Host "Warning: Invalid selection '$choice'. Please select a valid option (1 or B)." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            Show-GitConfigMenu
        }
    }
}

function Configure-GitIdentity {

    Write-Host ""

    $identity = Get-ItemProperty "HKCU:\Software\Microsoft\Office\16.0\Common\Identity" -ErrorAction SilentlyContinue

    $Email = Get-PropertyIfExists -Object $identity -PropertyName "ADUserName"
    if (-not $Email) {
        $Email = Read-Host "Enter your email address"
    }

    if ($Email) {
        Write-Host "Setting Git email to $Email" -ForegroundColor Cyan
        git config --global user.email $Email *> $null
    }

    $Name = Get-PropertyIfExists -Object $identity -PropertyName "ADUserDisplayName"
    if (-not $Name) {
        $Name = Read-Host "Enter your name"
    }

    if ($Name) {
        Write-Host "Setting Git username to $Name" -ForegroundColor Cyan
        git config --global user.name $Name *> $null
    }

    Write-Host "Git configuration applied successfully." -ForegroundColor Green

    Pause
    Show-GitConfigMenu
}

function Show-WSLMenu {
    Clear-Host
    Write-Host "Running as Administrator" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor DarkCyan
    Write-Host "             Windows Subsystem for Linux (WSL)" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor DarkCyan
    Write-Host "1. Install WSL and Configure Distro" -ForegroundColor Gray
    Write-Host "2. Unregister WSL Distro" -ForegroundColor Gray
    Write-Host "B. Back" -ForegroundColor Gray

    $choice = Read-Host "Select an option"

    switch ($choice) {
        '1' { Install-AndConfigureWSL }
        '2' { Unregister-WSLDistro }
        'B' { Show-MainMenu }
        default { 
            Write-Host "Warning: Invalid selection '$choice'. Please select a valid option (1, 2, or B)." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            Show-WSLMenu
        }
    }
}

function Install-AndConfigureWSL {

    Write-Host ""

    # Set the current directory to the automation root folder.
    $scriptDir = Split-Path (Split-Path  $PSCommandPath -Parent) -Parent
    Set-Location $scriptDir
    write-Host "Set current directory to repository root: $scriptDir" -ForegroundColor Green

    # Check and enable required Windows optional features.
    Write-Host "Checking required Windows features are enabled..." -ForegroundColor Cyan
    $requiredFeatures = @(
        "Microsoft-Windows-Subsystem-Linux",
        "VirtualMachinePlatform"
    )
        
    foreach ($featureName in $requiredFeatures) {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName $featureName

        if ($feature.State -eq "Enabled") {
            Write-Host "$featureName is already enabled" -ForegroundColor Yellow
        }
        else {
            Write-Host "$featureName is not enabled. Enabling now..." -ForegroundColor Green
            dism.exe /online /enable-feature /featurename:$featureName /all /norestart
        }
    }
    
    # Set WSL Setting default to WSL 2
    Write-Host "Setting WSL default version to 2" -ForegroundColor Cyan
    wsl --set-default-version 2

    # Set WSL Networking settings
    Write-Host "Apply configuration for wslconfig" -ForegroundColor Cyan
    $wslConfig = "$env:USERPROFILE\.wslconfig"
    $wslConfigContent = "[wsl2]`nnetworkingMode=mirrored`n[experimental]`nhostAddressLoopback=true`nbestEffortDnsParsing=true`nsparseVhd=true"
    Set-Content -Path $wslConfig -Value $wslConfigContent -Encoding ascii

    # Skip installation if the distro already exists, but keep post-install setup available.
    $installedDistros = wsl --list --quiet
    $distroAlreadyInstalled = @($installedDistros | ForEach-Object { $_.Trim() }) -contains $WSL_DISTRO

    if ($distroAlreadyInstalled) {
        Write-Host "$WSL_DISTRO is already installed." -ForegroundColor Yellow
    }
    else {
        Write-Host "Proceeding with installation of $WSL_DISTRO..." -ForegroundColor Cyan
        wsl --install -d $WSL_DISTRO --no-launch

        if ($LASTEXITCODE -eq 0) {
            Write-Host "$WSL_DISTRO installation completed successfully." -ForegroundColor Green
        }
        else {
            throw "Failed to install $WSL_DISTRO. Please check the error messages above and try again."
        }
    }

    Write-Host "Installing Ansible and rsync on $WSL_DISTRO..." -ForegroundColor Cyan
    $installCmd = "if command -v apt-get &> /dev/null; then apt-get update && apt-get install -y ansible rsync; elif command -v pacman &> /dev/null; then pacman-key --init && pacman-key --populate && pacman -Syu --noconfirm ansible rsync; else echo 'Unsupported package manager'; exit 1; fi"
    wsl -d $WSL_DISTRO -u root -- bash -lc "$installCmd"
    Write-Host "Ansible and rsync installed successfully on $WSL_DISTRO" -ForegroundColor Green

    Write-Host "Copying repository files to $WSL_DISTRO..." -ForegroundColor Cyan
    
    # Convert to forward slashes first so WSL does not drop backslashes from C:\ paths.
    $scriptDirForWsl = $scriptDir -replace '\\', '/'
    $srcWsl = wsl -d $WSL_DISTRO -u root -- wslpath -a "$scriptDirForWsl"
    if ($LASTEXITCODE -ne 0 -or -not $srcWsl) {
        throw "Failed to convert Windows repo path '$scriptDir' to a WSL path."
    }

    $srcWsl = $srcWsl.Trim()
    $destRoot = "/root/.automation"

    wsl -d $WSL_DISTRO -u root -- bash -lc "mkdir -p '$destRoot' && rsync -av --delete '$srcWsl/' '$destRoot/'"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to copy repository files into $WSL_DISTRO using rsync."
    }

    Write-Host "Repository files copied successfully to ${WSL_DISTRO}:${destRoot}" -ForegroundColor Green

    Write-Host "Windows Subsystem for Linux (WSL) setup completed! Ensure to restart your computer for all changes to take effect." -ForegroundColor Green
    Pause
    Show-WSLMenu
}

function Unregister-WSLDistro {

    Write-Host ""
    Write-Host "Checking if $WSL_DISTRO is installed..."
    $distroList = wsl --list --quiet 2>$null
    
    if (-not ($distroList -contains $WSL_DISTRO)) {
        Write-Host "$WSL_DISTRO is not installed on this system." -ForegroundColor Yellow
        Pause
        Show-WSLMenu
        return
    }

    Write-Host "Unregistering $WSL_DISTRO"
    wsl --unregister $WSL_DISTRO

    if ($LASTEXITCODE -eq 0) {
        Write-Host "$WSL_DISTRO was unregistered successfully."
    }
    else {
        Write-Host "Failed to unregister $WSL_DISTRO."
    }

    Pause
    Show-WSLMenu
}

Show-MainMenu