.PHONY: all bootstrap wsl-dev wsl-base wsl-cloud help

# Linux Distro to be install in WSL
WSL_DISTRO ?= Ubuntu-22.04
WSL_USER ?= bantler

# Directory that contains this Makefile
THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# Repo root (automation/)
REPO_ROOT_WIN := $(CURDIR)/../..

# WSL path version of repo root
REPO_ROOT_WSL := $(shell wsl -d $(WSL_DISTRO) -- wslpath -a "$(REPO_ROOT_WIN)")

# Default Ansible directory inside the mounted repo in WSL
WSL_ANSIBLE_DIR ?= $(REPO_ROOT_WSL)/scripts/local environments/wsl/ansible

help:
	@printf "Usage:\n  make win         Run Windows PowerShell setup\n  make wsl         Run WSL install script (run inside WSL or have bash available)\n  make wsl-ansible Run Ansible playbook (requires Ansible)\n"

bootstrap:
	@echo "Running Windows Bootstrap setup..."
	powershell.exe -NoProfile -ExecutionPolicy Bypass -File ./windows/bootstrap.ps1 -WSL_DISTRO $(WSL_DISTRO)

wsl-base:
	wsl -d $(WSL_DISTRO) -u root -- bash -elc "cd '$(WSL_ANSIBLE_DIR)' && ANSIBLE_CONFIG='$(WSL_ANSIBLE_DIR)/ansible.cfg' ansible-playbook -i inventory/local.ini playbooks/base.yaml -e wsl_default_user=$(WSL_USER)"

wsl-dev:
	wsl -d $(WSL_DISTRO) -u root -- bash -lc "cd '$(WSL_ANSIBLE_DIR)' && ANSIBLE_CONFIG='$(WSL_ANSIBLE_DIR)/ansible.cfg' ansible-playbook -i inventory/local.ini playbooks/dev.yaml"

wsl-cloud:
	wsl -d $(WSL_DISTRO) -u root -- bash -lc "cd '$(WSL_ANSIBLE_DIR)' && ANSIBLE_CONFIG='$(WSL_ANSIBLE_DIR)/ansible.cfg' ansible-playbook -i inventory/local.ini playbooks/cloud.yaml"