#!/bin/bash

YELLOW="\033[1;33m"
RED="\033[0;31m"
GREEN="\033[0;32m"
ENDCOLOR="\033[0m"

log_file="/var/log/maintenance.log"

step() {
    echo -e "${YELLOW}[+]${ENDCOLOR} ${1}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') [+] ${1}" >>"$log_file"
}

error() {
    echo -e "${RED}[-]${ENDCOLOR} ${1}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') [-] ${1}" >>"$log_file"
    exit 1
}

success() {
    echo -e "${GREEN}[+]${ENDCOLOR} ${1}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') [+] ${1}" >>"$log_file"
}

update_system() {
    step "Updating package lists"
    sudo apt-get update -qq || error "Failed to update package lists"

    step "Upgrading installed packages"
    sudo apt-get full-upgrade -y -qq || error "Failed to upgrade packages"
}

clean_apt() {
    step "Cleaning apt cache"
    sudo apt-get clean -qq || error "Failed to clean apt cache"
    sudo apt-get autoclean -qq || error "Failed to autoclean apt cache"
}

remove_old_configs() {
    local old_configs=()
    while read -r config; do
        old_configs+=("$config")
    done < <(dpkg -l | grep "^rc" | awk '{print $2}')
    if [ "${#old_configs[@]}" -gt 0 ]; then
        step "Removing old config files"
        sudo apt-get purge -y -qq "${old_configs[@]}" || error "Failed to remove old config files"
    else
        success "No old config files found"
    fi
}

remove_old_kernels() {
    step "Removing old kernels"
    sudo apt-get --purge autoremove -y -qq || error "Failed to remove old kernels"
}

remove_old_logs() {
    step "Removing old log files"
    sudo find /var/log/ -type f -mtime +7 -exec rm -f {} + || error "Failed to remove old log files"
}

empty_trash() {
    step "Emptying trash"
    sudo find /home/ /root/ -depth -type d -prune -o \( -path '/proc' -o -path '/dev' -o -path '/sys' \) -prune -o -type d -name '.*' -prune -o -type d -not -readable -prune -o -type d -path '*/.local/share/Trash/*' -print -delete -print 2>/dev/null
    sudo find /root/.local/share/Trash -mindepth 1 -delete -print 2>/dev/null
    sudo rm -rf /tmp/*
}

rotate_journal_logs() {
    step "Rotating journal logs and freeing up space"
    journalctl --rotate --vacuum-time=1d >/dev/null 2>&1 || error "Failed to rotate journal logs"
}

main() {
    echo "" >>"$log_file"
    echo "$(date +'%Y-%m-%d %H:%M:%S') Starting maintenance script" >>"$log_file"
    update_system
    clean_apt
    remove_old_configs
    remove_old_kernels
    remove_old_logs
    empty_trash
    rotate_journal_logs
    success "Script finished!"
    echo "$(date +'%Y-%m-%d %H:%M:%S') Maintenance script finished" >>"$log_file"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    if [[ $(id -u) -ne 0 ]]; then
        error "This script must be run with root privileges"
    fi

    main "$@"
fi
