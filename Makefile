.PHONY: all help bootstrap wsl-dev wsl-base wsl-cloud wsl-rsync

# Linux Distro to be install in WSL
WSL_DISTRO ?= Ubuntu-24.04
WSL_USER ?= bantler
WINDOWS_USER ?= $(USERNAME)

# Get current git repo root
GIT_REPO_ROOT := $(shell git rev-parse --show-toplevel)

# Root win-sible directory inside WSL
WSL_SIBLE_DIR ?= /root/.automation

help:
	@echo Usage:
	@echo   make bootstrap  Runs baseline installations for dev tools and applications in Windows
	@echo   make wsl-base   Runs baseline installations in WSL using Ansible playbook
	@echo   make wsl-dev    Runs development environment setup in WSL using Ansible playbook
	@echo   make wsl-cloud  Runs cloud environment setup in WSL using Ansible playbook
	@echo   make wsl-rsync  Rsync this repo from Windows to WSL path

bootstrap:
	@echo "Running Windows Bootstrap setup..."
	powershell.exe -NoProfile -ExecutionPolicy Bypass -File ./windows/bootstrap.ps1 -WSL_DISTRO $(WSL_DISTRO)

wsl-base:
	wsl -d $(WSL_DISTRO) -u root -- bash -elc "cd '$(WSL_SIBLE_DIR)/wsl/ansible/' && ANSIBLE_CONFIG='$(WSL_SIBLE_DIR)/wsl/ansible/ansible.cfg' ansible-playbook -i inventory/local.ini playbooks/base.yaml -e wsl_default_user=$(WSL_USER) -e windows_user=$(WINDOWS_USER)"

wsl-dev:
	wsl -d $(WSL_DISTRO) -u root -- bash -lc "cd '$(WSL_SIBLE_DIR)/wsl/ansible/' && ANSIBLE_CONFIG='$(WSL_SIBLE_DIR)/wsl/ansible/ansible.cfg' ansible-playbook -i inventory/local.ini playbooks/dev.yaml"

wsl-cloud:
	wsl -d $(WSL_DISTRO) -u root -- bash -lc "cd '$(WSL_SIBLE_DIR)/wsl/ansible/' && ANSIBLE_CONFIG='$(WSL_SIBLE_DIR)/wsl/ansible/ansible.cfg' ansible-playbook -i inventory/local.ini playbooks/cloud.yaml"

wsl-rsync:
	wsl -d $(WSL_DISTRO) -u root -- bash -lc "rsync -av /mnt/c/Users/$(WINDOWS_USER)/source/repos/github/win-sible/ $(WSL_SIBLE_DIR)"
	