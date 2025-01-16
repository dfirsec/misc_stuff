#!/bin/bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Enable debug mode
set -x

# Color definitions using printf for better portability
readonly RED=$(printf '\033[31m')
readonly GREEN=$(printf '\033[32m')
readonly YELLOW=$(printf '\033[33m')
readonly NC=$(printf '\033[0m')

# Configuration
readonly DEBUG=${DEBUG:-0}
readonly LOG_FILE="/var/log/install_script.log"
readonly HWE=${HWE:-"-hwe-22.04"}  # Default to HWE kernel

# Dependencies array
readonly DEPENDENCIES=(
    aptitude
    python3-dev
    python3-pip
    python3-venv
    libjpeg8-dev
    zlib1g-dev
    libhyperscan5
    libhyperscan-dev
    unzip
    p7zip-full
    rar
    unace-nonfree
    cabextract
    yara
    tcpdump
    genisoimage
    qemu-system-x86
    qemu-system-common
    qemu-utils
    linux-tools-virtual${HWE}
    linux-cloud-tools-virtual${HWE}
    xrdp
)

# Logging function with timestamps
log() {
    local level=$1
    shift
    local message="$*"
    echo -e "[$(date -Iseconds)] [${level}] ${message}" | tee -a "$LOG_FILE"
    [[ $DEBUG -eq 1 && $level == "DEBUG" ]] && echo "[DEBUG] $message" >&2
}

# Error handler
error() {
    log "ERROR" "${RED}$*${NC}" >&2
    log "ERROR" "Line number: ${BASH_LINENO[0]}"
    log "ERROR" "Command: $BASH_COMMAND"
    exit 1
}

# Trap errors and cleanup
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log "ERROR" "Script failed with exit code $exit_code"
        log "ERROR" "Last command: $BASH_COMMAND"
        log "ERROR" "Stack trace:"
        local frame=0
        while caller $frame; do
            ((frame++))
        done
    fi
    exit $exit_code
}
trap cleanup EXIT

# Check for root privileges
check_root() {
    [[ $(id -u) -eq 0 ]] || error "This script must be run as root or with sudo privileges."
}

# Check if reboot is required
check_reboot_required() {
    [[ -f /var/run/reboot-required ]] && {
        log "WARN" "${YELLOW}A reboot is required to proceed with the installation.${NC}"
        log "INFO" "Please reboot and re-run this script to continue."
        exit 1
    }
}

# Check KVM support
check_kvm_support() {
    grep -Eq 'vmx|svm' /proc/cpuinfo || \
        log "WARN" "${YELLOW}CPU does not support hardware virtualization (KVM).${NC}"
}

# Install system dependencies
install_dependencies() {
    log "INFO" "${YELLOW}Installing system dependencies...${NC}"
    
    # Debug: Show what's in DEPENDENCIES array
    log "DEBUG" "Dependencies to install: ${DEPENDENCIES[*]}"
    
    # Update package list and upgrade system
    log "INFO" "Updating package list..."
    apt-get update || error "Failed to update package list"
    
    log "INFO" "Upgrading system packages..."
    apt-get upgrade -y || error "Failed to upgrade system packages"
    
    # Install all dependencies in a single command
    log "INFO" "Installing dependencies..."
    apt-get install -y --no-install-recommends "${DEPENDENCIES[@]}" || {
        local status=$?
        log "ERROR" "apt-get install failed with status $status"
        error "Failed to install dependencies"
    }
    
    log "INFO" "${GREEN}All dependencies installed successfully.${NC}"
}

# Configure XRDP with here-doc
configure_xrdp() {
    log "INFO" "${YELLOW}Configuring XRDP...${NC}"
    systemctl stop xrdp xrdp-sesman

    # Backup original configs if not already backed up
    for file in /etc/xrdp/{xrdp,sesman}.ini /etc/X11/Xwrapper.config; do
        [[ -f "${file}_orig" ]] || cp "$file" "${file}_orig"
    done

    # Update XRDP configuration
    sed -i \
        -e 's/port=3389/port=vsock:\/\/-1:3389/' \
        -e 's/security_layer=negotiate/security_layer=rdp/' \
        -e 's/crypt_level=high/crypt_level=none/' \
        -e 's/bitmap_compression=true/bitmap_compression=false/' \
        /etc/xrdp/xrdp.ini

    # Create startubuntu.sh if it doesn't exist
    [[ -e /etc/xrdp/startubuntu.sh ]] || cat > /etc/xrdp/startubuntu.sh << 'EOF'
#!/bin/sh
export GNOME_SHELL_SESSION_MODE=ubuntu
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
exec /etc/xrdp/startwm.sh
EOF
    chmod a+x /etc/xrdp/startubuntu.sh

    # Update SESMAN configuration
    sed -i \
        -e 's/startwm/startubuntu/' \
        -e 's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/' \
        /etc/xrdp/sesman.ini

    # Configure X server
    sed -i 's/allowed_users=console/allowed_users=anybody/' /etc/X11/Xwrapper.config

    # Configure kernel modules
    echo "blacklist vmw_vsock_vmci_transport" > /etc/modprobe.d/blacklist-vmw_vsock_vmci_transport.conf
    echo "hv_sock" > /etc/modules-load.d/hv_sock.conf

    # Configure PolicyKit
    cat > /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla << 'EOF'
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF

    systemctl daemon-reload
    systemctl start xrdp
    log "INFO" "${GREEN}XRDP configured successfully.${NC}"
}

# Prompt for reboot with timeout
prompt_reboot() {
    echo -e "\n*** A system reboot is required to complete the installation ***"
    read -r -t 30 -p "Would you like to reboot now? (y/N, defaults to N in 30s): " answer || true
    case "${answer:-n}" in
        [Yy]*)
            log "INFO" "Rebooting system..."
            reboot
            ;;
        *)
            log "INFO" "Installation complete. Please reboot your system later to finalize changes."
            exit 0
            ;;
    esac
}

main() {
    log "INFO" "${YELLOW}Starting combined installation script...${NC}"
    check_root
    check_kvm_support
    install_dependencies
    configure_xrdp
    check_reboot_required
    log "INFO" "${GREEN}Installation and configuration completed successfully.${NC}"
    prompt_reboot
}

main "$@"
