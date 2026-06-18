.PHONY: all help bootstrap wsl-dev wsl-base wsl-cloud sync-to-wsl

# Linux Distro to be install in WSL
WSL_DISTRO ?= Ubuntu-24.04
WSL_USER ?= bantler
WINDOWS_USER ?= $(USERNAME)

# Default Ansible directory inside the mounted repo in WSL
WSL_ANSIBLE_DIR ?= /root/.automation/wsl/ansible

help:
	@echo Usage:
	@echo   make bootstrap  Runs baseline installations for dev tools and applications in Windows
	@echo   make wsl-base   Runs baseline installations in WSL using Ansible playbook
	@echo   make wsl-dev    Runs development environment setup in WSL using Ansible playbook
	@echo   make wsl-cloud  Runs cloud environment setup in WSL using Ansible playbook
	@echo   make sync-to-wsl Rsync this repo from Windows to WSL path

bootstrap:
	@echo "Running Windows Bootstrap setup..."
	powershell.exe -NoProfile -ExecutionPolicy Bypass -File ./windows/bootstrap.ps1 -WSL_DISTRO $(WSL_DISTRO)

wsl-base:
	wsl -d $(WSL_DISTRO) -u root -- bash -elc "cd '$(WSL_ANSIBLE_DIR)' && ANSIBLE_CONFIG='$(WSL_ANSIBLE_DIR)/ansible.cfg' ansible-playbook -i inventory/local.ini playbooks/base.yaml -e wsl_default_user=$(WSL_USER) -e windows_user=$(WINDOWS_USER)"

wsl-dev:
	wsl -d $(WSL_DISTRO) -u root -- bash -lc "cd '$(WSL_ANSIBLE_DIR)' && ANSIBLE_CONFIG='$(WSL_ANSIBLE_DIR)/ansible.cfg' ansible-playbook -i inventory/local.ini playbooks/dev.yaml -e windows_user=$(WINDOWS_USER)"

wsl-cloud:
	wsl -d $(WSL_DISTRO) -u root -- bash -lc "cd '$(WSL_ANSIBLE_DIR)' && ANSIBLE_CONFIG='$(WSL_ANSIBLE_DIR)/ansible.cfg' ansible-playbook -i inventory/local.ini playbooks/cloud.yaml -e windows_user=$(WINDOWS_USER)"

wsl-rsync:
	wsl -d $(WSL_DISTRO) -u root -- bash -lc "mkdir -p '$destRoot' && rsync -av --delete '$srcWsl/' '$destRoot/'"
	