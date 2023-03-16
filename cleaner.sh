#!/bin/bash

set -euo pipefail

YELLOW="\033[1;33m"
RED="\033[0;31m"
GREEN="\033[0;32m"
ENDCOLOR="\033[0m"

step() {
    echo -e "${YELLOW}[+]${ENDCOLOR} ${1}"
}

error() {
    echo -e "${RED}[-]${ENDCOLOR} ${1}"
    exit 1
}

success() {
    echo -e "${GREEN}[+]${ENDCOLOR} ${1}"
}

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "Error: must be root"
    fi
}

update_system() {
    step "Updating package lists"
    apt-get update -q

    step "Upgrading installed packages"
    apt-get full-upgrade -y -q
}

clean_apt() {
    step "Cleaning apt cache"
    apt-get clean -q
    apt-get autoclean -q
}

remove_old_configs() {
    local old_configs
    old_configs=$(dpkg -l | grep "^rc" | awk '{print $2}' || true)
    if [ -n "$old_configs" ]; then
        step "Removing old config files"
        apt-get purge -y "${old_configs[@]}"
    else
        success "No old config files found"
    fi
}

remove_old_kernels() {
    step "Removing old kernels"
    apt-get --purge autoremove -y -q
}

remove_old_logs() {
    step "Removing old log files"
    rm -f /var/log/*gz
}

empty_trash() {
    step "Emptying trash"
    sudo find /home/ -type d ! -perm -g+r,u+r,o+r -prune -o -type d -path '*/.local/share/Trash/*' -exec rm -rf {} +
    sudo find /root/.local/share/Trash -mindepth 1 -exec rm -rf {} + 2>/dev/null || true
    sudo rm -rf /tmp/*
}

rotate_journal_logs() {
    step "Rotating journal logs and freeing up space"
    journalctl --rotate --vacuum-time=1d
}

main() {
    check_root
    update_system
    clean_apt
    remove_old_configs
    remove_old_kernels
    remove_old_logs
    empty_trash
    rotate_journal_logs
    success "Script finished!"
}

main
