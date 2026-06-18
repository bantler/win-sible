Ansible WSL setup

Usage:

- Run the playbook against a WSL distro (local or remote) with:

  ansible-playbook -i <target>, playbook.yml --ask-become-pass

Defaults and distro-specific package handling are in the role defaults.
