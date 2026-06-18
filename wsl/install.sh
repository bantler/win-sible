#!/bin/bash

# To install this script run "curl -fsSL https://raw.githubusercontent.com/bantler/dotfiles/refs/heads/main/setup/wsl/install.sh | sudo bash"

# # Check if the script is run as root
# if [[ $EUID -ne 0 ]]; then
#    echo "This script must be run as root. Try using sudo."
#    exit 1
# fi

# # Prompt user for new root password securely
# echo "Enter new root password:"
# read -s new_password </dev/tty

# echo "Confirm new root password:"
# read -s confirm_password </dev/tty

# # Check if passwords match
# if [[ "$new_password" != "$confirm_password" ]]; then
#     echo "Error: Passwords do not match."
#     exit 1
# fi

# # Change root password
# echo "root:$new_password" | chpasswd

# # Check if the password change was successful
# if [[ $? -eq 0 ]]; then
#     echo "Root password changed successfully."
# else
#     echo "Failed to change root password."
#     exit 1
# fi

# # Prompt for username
# echo "Enter new username"
# read -s username </dev/tty

# echo "Enter password for $username: "
# read -s password </dev/tty

# # Check if the user already exists
# if id "$username" &>/dev/null; then

#     # Prompt for user deletion
#     read -p "User '$username' already exists! Do you want to delete the user $username? (y/n): " del_user </dev/tty
#     if [[ $del_user == "y" ]]; then
#         sudo userdel $username -f
#         echo "Existing user $username deleted"
#         sudo rm -rf /home/$username
#         echo "Existing user $username home directory deleted. A fresh user will now be created."

#         # Create the user
#         sudo useradd -m -s /bin/bash "$username"

#         # Change user password
#         echo "$username:$password" | sudo chpasswd

#         # Prompt for sudo access
#         read -p "Grant sudo access to $username? (y/n): " sudo_access </dev/tty
#         if [[ $sudo_access == "y" ]]; then
#             sudo usermod -aG sudo "$username"
#             echo "$username has been added to the sudo group."
#         fi

#         echo "User $username created successfully."
#     fi
# else
#     # Create the user
#     sudo useradd -m -s /bin/bash "$username"

#     # Change user password
#     echo "$username:$password" | sudo chpasswd

#     # Prompt for sudo access
#     read -p "Grant sudo access to $username? (y/n): " sudo_access </dev/tty
#     if [[ $sudo_access == "y" ]]; then
#         sudo usermod -aG sudo "$username"
#         echo "$username has been added to the sudo group."
#     fi

#     echo "User $username created successfully."
# fi

# Update the list of packages
echo "Install updates and upgrades"
apt-get update
apt-get upgrade -y

# Install pre-requisite packages.
echo "Installing common pre-requisite packages"
apt-get install -y apt-transport-https software-properties-common

# Get the version of Ubuntu
source /etc/os-release

# Download the Microsoft repository keys
wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb

# Register the Microsoft repository keys
sudo dpkg -i packages-microsoft-prod.deb

# Delete the Microsoft repository keys file
rm packages-microsoft-prod.deb

# Install the HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

# Verify the key's fingerprint
gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint

# Add offical hasicorp repositories
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update all packages
echo "Install updates and updates"
apt-get update
apt-get upgrade -y

# Get default user
echo "Get default user"
default_user=$(getent passwd 1000 | cut -d: -f1)
echo $default_user

# Create sudo_as_admin_successful
echo "Creating sudo_as_admin_successful"
sudo -u $default_user touch /home/$default_user/.sudo_as_admin_successful

# Create hushlogin
echo "Creating hushlogin."
sudo -u $default_user touch /home/$default_user/.hushlogin

echo "Copy ssh key from windows or from WSL"
if [ -n "$WSL_DISTRO_NAME" ]; then
    echo "Running in WSL: $WSL_DISTRO_NAME"
    
    echo "Copying ssh key from windows"
    sudo -u $default_user cp -r /mnt/c/Users/$default_user/.ssh /home/$default_user/

    echo "Grant permissions to ssh"
    chmod 600 /home/$default_user/.ssh/id_ed25519
else
    echo "Not running in WSL, ssh keys will need copying manually before running this script"
fi

# Install yadm and clone dotfiles repo
echo "Installing yadm"
apt-get install yadm

echo "Clone dotfiles repo"
sudo -u $default_user yadm clone git@github.com:bantler/dotfiles.git -f

# Install starship
echo "Installing starship"
curl -sS https://starship.rs/install.sh | sh

# Install powershell
echo "Installing powershell"
apt-get install powershell -y

# Install Python and venv
echo "Installing python and venv"
apt-get install python3
apt-get install python3-venv -y

echo "Installing azure-cli"
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Terraform
echo "Installing Terraform"
apt-get install terraform

# Install tfenv
echo "Installing tfenv"
sudo -u $default_user git clone --depth=1 https://github.com/tfutils/tfenv.git /home/$default_user/.tfenv

# Install cmatrix
echo "Installing cmatrix"
apt-get install cmatrix -y

# Install bat
echo "Installing bat"
apt-get install bat -y

# Install fzf
echo "Installing fzf"
apt-get install fzf

# Install zoxide
echo "Installing zoxide"
apt-get install zoxide

# Install eza
echo "Installing eza"
apt-get install eza -y

# Install direnv
echo "Installing direnv"
apt-get install direnv

# Install jq
echo "Installing jq"
apt-get install jq -y

# Install zsh plugins
echo "Installing zsh plugins"
sudo -u $default_user git clone https://github.com/zsh-users/zsh-autosuggestions /home/$default_user/.zsh/zsh-autosuggestions
sudo -u $default_user git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /home/$default_user/.zsh/zsh-syntax-highlighting
sudo -u $default_user git clone https://github.com/zsh-users/zsh-completions.git /home/$default_user/.zsh/zsh-completions

# Install zsh shell
echo "Installing zsh shell"
sudo apt-get install -y zsh || exit 1

# Set Zsh as the default shell without switching immediately
echo "Changing shell to zsh for all users"
chsh -s $(which zsh) $USER || true
chsh -s $(which zsh) $default_user || true