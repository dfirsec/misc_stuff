#!/bin/bash

CYAN="\033[0;36m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
MAGENTA="\033[0;35m"
ENDCOLOR="\033[0m"

log_file="/var/log/maintenance.log"

step() {
    echo -e "${CYAN}[*]${ENDCOLOR} ${1}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') [+] ${1}" >>"$log_file"
}

error() {
    echo -e "${RED}[-]${ENDCOLOR} ${1}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') [-] ${2:-${1}}" >>"$log_file"
    return 1
}

success() {
    echo -e "${GREEN}[+]${ENDCOLOR} ${1}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') [+] ${1}" >>"$log_file"
}

warning() {
    echo -e "${YELLOW}[!]${ENDCOLOR} ${1}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') [!] ${1}" >>"$log_file"
}

info() {
    echo -e "${MAGENTA}[i]${ENDCOLOR} ${1}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') [i] ${1}" >>"$log_file"
}

update_system() {
    step "Updating package lists"
    if ! output=$(sudo apt-get update -qq 2>&1); then
        error "Failed to update package lists" "Failed to update package lists: $output"
    fi

    step "Upgrading installed packages"
    if ! output=$(sudo apt-get full-upgrade -y -qq 2>&1); then
        error "Failed to upgrade packages" "Failed to upgrade packages: $output"
    fi
}

clean_apt() {
    step "Cleaning apt cache"
    output=$(sudo apt-get clean -qq 2>&1) || error "Failed to clean apt cache: $output"
    output=$(sudo apt-get autoclean -qq 2>&1) || error "Failed to autoclean apt cache: $output"
}

remove_old_configs() {
    local old_configs=()
    while read -r config; do
        old_configs+=("$config")
    done < <(dpkg -l | grep "^rc" | awk '{print $2}')
    if [ "${#old_configs[@]}" -gt 0 ]; then
        step "Removing old config files"
        output=$(sudo apt-get purge -y -qq "${old_configs[@]}" 2>&1) || error "Failed to remove old config files: $output"
    else
        info "No old config files found"
    fi
}

remove_old_kernels() {
    step "Removing old kernels"
    output=$(sudo apt-get --purge autoremove -y -qq 2>&1) || error "Failed to remove old kernels: $output"
}

remove_old_logs() {
    step "Removing old log files"
    output=$(sudo find /var/log/ -type f -mtime +7 -exec rm -f {} + 2>&1) || error "Failed to remove old log files: $output"
}

check_protected() {
    local file=$1
    local owner
    local permissions

    owner=$(stat -c '%U' "$file")
    permissions=$(stat -c '%A' "$file")

    # Check if the file is owned by root or a system user
    if [[ "$owner" == "root" || "$owner" == "system" ]]; then
        return 0
    fi

    # Check if the file has restrictive permissions
    if [[ "$permissions" =~ ^[drwx-]{3}[-]{3} ]]; then
        return 0
    fi

    return 1
}

empty_trash() {
    step "Emptying trash"
    if ! output=$(find /home/ /root/ -depth -type d \( -path '*/shared-drives' -o -path '*/SharedDrives' -o -path '*/lost+found' -o -path '/mnt' -o -path '/media' -o -name '.*' \) -prune -o -type d -path '*/.local/share/Trash/*' -delete -print 2>&1); then
        error "Failed to empty trash: $output"
    fi

    if [ -d /root/.local/share/Trash ]; then
        if [ -z "$(ls -A /root/.local/share/Trash)" ]; then
            success "Successfully emptied root trash"
        else
            error "root trash was not emptied"
            echo "$(date +'%Y-%m-%d %H:%M:%S') [i] Contents of trash at /root/.local/share/Trash after emptying: $(ls /root/.local/share/Trash)" >>"$log_file"
        fi
    else
        info "Trash at /root/.local/share/Trash does not exist"
    fi

    step "Checking file/directory protections"

    shopt -s nullglob dotglob # Enable nullglob and dotglob to include hidden files and directories
    for file in /tmp/*; do
        if [[ -f "$file" || -d "$file" ]]; then
            if check_protected "$file"; then
                info "Protected: $file (skipping removal)"
                continue
            fi

            echo "Removing $file..."
            output=$(rm -rf "$file") || error "Failed to empty /tmp: $output"
        fi
    done
    shopt -u nullglob dotglob # Disable nullglob and dotglob after loop completion
}

rotate_journal_logs() {
    if [ -d /run/systemd/journal/ ]; then
        step "Rotating journal logs and freeing up space"
        output=$(journalctl --rotate --vacuum-time=1d 2>&1) || error "Failed to rotate journal logs: $output"
    else
        error "Failed to rotate journal logs: Journal service may not be running"
    fi
}

run_all() {
    echo -e "\nRunning all maintenance tasks...\n"
    update_system
    clean_apt
    remove_old_configs
    remove_old_kernels
    remove_old_logs
    empty_trash
    rotate_journal_logs

    success "All maintenance tasks completed!"
}

main_menu() {
    echo ""
    echo "Maintenance Script"
    echo "==================="
    echo "1. Update system"
    echo "2. Clean apt"
    echo "3. Remove old config files"
    echo "4. Remove old kernels"
    echo "5. Remove old log files"
    echo "6. Empty trash"
    echo "7. Rotate journal logs"
    echo "8. All"
    echo "0. Exit"

    read -rp "Enter your choice: " choice

    case $choice in
    1) update_system ;;
    2) clean_apt ;;
    3) remove_old_configs ;;
    4) remove_old_kernels ;;
    5) remove_old_logs ;;
    6) empty_trash ;;
    7) rotate_journal_logs ;;
    8) run_all ;;
    0)
        echo "Exiting..."
        exit
        ;;
    *) echo "Invalid choice" ;;
    esac

    main_menu
}

if [[ $(id -u) -ne 0 ]]; then
    echo -e "${RED}[-] This script must be run with root privileges${ENDCOLOR}"
    exit 1
else
    main_menu
fi
