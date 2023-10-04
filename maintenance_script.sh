#!/bin/bash

CYAN="\033[0;36m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
GREEN="\033[0;32m"
ENDCOLOR="\033[0m"

if [[ $(id -u) -ne 0 ]]; then
    error "This script must be run with root privileges"
fi

reboot_required=0

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

check_filesystem() {
    step "Forcing fsck on the next boot to check filesystem for errors"
    sudo touch /forcefsck || error "Failed to create /forcefsck"
    reboot_required=1
}

# Check Disk Space
check_disk_space() {
    step "Checking disk space"
    local limit=90 # set the limit as per your need
    local usage
    usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$usage" -gt "$limit" ]; then
        error "Disk space usage is above $limit%"
    fi
}

# Check for Failed Systemd Services
check_failed_services() {
    step "Checking for failed systemd services"
    if systemctl --failed | grep 'loaded units listed'; then
        success "No failed systemd services found"
    else
        error "Some systemd services have failed"
    fi
}

# Reboot Requirement Check
check_reboot_required() {
    step "Checking if a reboot is required"
    if [ -f /var/run/reboot-required ]; then
        error "A reboot is required. Please reboot the system at your earliest convenience."
    else
        success "No reboot required"
    fi
}

# Review Authentication Logs
review_auth_logs() {
    local failed_attempts
    failed_attempts=$(grep -c "Failed password" /var/log/auth.log)

    if [ "$failed_attempts" -gt 20 ]; then
        error "$failed_attempts failed login attempts found in auth.log"
    else
        success "No unusual activity found in auth.log"
    fi
}

# Update System
update_system() {
    step "Updating package lists"
    sudo apt-get update -qq || error "Failed to update package lists"

    step "Upgrading installed packages"
    sudo apt-get full-upgrade -y -qq || error "Failed to upgrade packages"
}

# Clean
clean_apt() {
    step "Cleaning apt cache"
    sudo apt-get clean -qq || error "Failed to clean apt cache"
    sudo apt-get autoclean -qq || error "Failed to autoclean apt cache"
}

# Remove Old Config Files
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

    # Empty trash directories for all users in /home/
    for user_dir in /home/*; do
        if [ -d "$user_dir/.local/share/Trash" ]; then
            rm -rf "$user_dir/.local/share/Trash"/*
        fi
    done

    # Empty trash for root user
    rm -rf /root/.local/share/Trash/*

    # Clear the /tmp/ directory
    rm -rf /tmp/*
}

# NTP Sync
ntp_sync() {
    step "Synchronizing system clock with NTP servers"
    sudo ntpdate pool.ntp.org || error "Failed to sync with NTP"
}

rotate_journal_logs() {
    step "Rotating journal logs and freeing up space"
    journalctl --rotate --vacuum-time=1d >/dev/null 2>&1 || error "Failed to rotate journal logs"
}

adjust_clock() {
    step "Adjusting hardware clock"
    echo -e "${CYAN}[i]${ENDCOLOR} Current clock: $(date)"
    sudo hwclock --hctosys
    echo -e "${CYAN}[i]${ENDCOLOR} Updated clock: $(date)"
}

flush_dns() {
    step "Flushing DNS cache"
    sudo systemd-resolve --flush-caches
}

complete_maintenance() {
    echo "" >>"$log_file"
    echo "$(date +'%Y-%m-%d %H:%M:%S') Starting maintenance script" >>"$log_file"
    echo "Running all maintenance tasks..."
    ntp_sync
    update_system
    rotate_journal_logs
    check_failed_services
    check_reboot_required
    review_auth_logs
    clean_apt
    remove_old_configs
    remove_old_kernels
    empty_trash
    remove_old_logs
    check_filesystem
    adjust_clock
    flush_dns
    success "All maintenance tasks completed!"
    echo "$(date +'%Y-%m-%d %H:%M:%S') Maintenance script finished" >>"$log_file"
}

main_menu() {
    while true; do
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
        echo "8. Adjust hardware clock"
        echo "9. Check Filesystem Errors"
        echo "10. Check Failed Systemd Services"
        echo "11. Check Reboot Requirement"
        echo "12. Review Authentication Logs"
        echo "13. NTP Sync"
        echo "14. All - Complete Maintenance"
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
        8) adjust_clock ;;
        9) check_filesystem ;;
        10) check_failed_services ;;
        11) check_reboot_required ;;
        12) review_auth_logs ;;
        13) ntp_sync ;;
        14) complete_maintenance ;;
        0)
            echo "Exiting..."
            break
            ;;
        *) echo "Invalid choice" ;;
        esac
    done
}

# Call the main_menu function
main_menu

if [ $reboot_required -eq 1 ]; then
    echo -e "${RED}[!]${ENDCOLOR} It's recommended to reboot the system for the changes to take effect."
fi
