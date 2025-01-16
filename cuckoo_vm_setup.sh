#!/bin/bash

trap cleanup EXIT
set -euo pipefail

# Cuckoo Sandbox VM setup script for Ubuntu 22.04 LTS
# Tested on Ubuntu 22.04 LTS with HWE kernel
# This script installs all dependencies and configures XRDP for Cuckoo Sandbox VM

# The following commands can be used to create a VM for Cuckoo Sandbox:
# Set-VMProcessor -VMName "Cuckoo" -ExposeVirtualizationExtensions $true
# Set-VMFirmware -VMName "Cuckoo" -EnableSecureBoot Off
# Set-VM -VMName "Cuckoo" -ProcessorCount 4
# Set-VM -VMName "Cuckoo" -SwitchName "External"
# Set-VM -VMName "Cuckoo" -EnhancedSessionTransportType HvSocket

# Color definitions using printf for better portability
RED=$(printf '\033[31m')
GREEN=$(printf '\033[32m')
YELLOW=$(printf '\033[33m')
NC=$(printf '\033[0m')

# Configuration
DEBUG=${DEBUG:-0}
LOG_FILE="/var/log/install_script.log"
touch "$LOG_FILE" 2>/dev/null || sudo touch "$LOG_FILE"
chmod 644 "$LOG_FILE" 2>/dev/null || sudo chmod 644 "$LOG_FILE"
HWE=${HWE:-"-hwe-24.04"} # Default to HWE kernel

# Dependencies array
DEPENDENCIES=(
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
    linux-tools-virtual"${HWE}"
    linux-cloud-tools-virtual"${HWE}"
    xrdp
)

# Logging function with timestamps
log() {
    local level=$1
    shift
    local message="$*"
    echo -e "[$(date -Iseconds)] [${level}] ${message}" | tee -a "$LOG_FILE"
    if [[ $DEBUG -eq 1 ]] && [[ $level == "DEBUG" ]]; then
        echo "[DEBUG] $message" >&2
    fi
    return 0
}

# Error handler
error() {
    log "ERROR" "${RED}$*${NC}" >&2
    log "ERROR" "Line number: ${BASH_LINENO[0]}"
    log "ERROR" "Command: $BASH_COMMAND"
    exit 1
}

cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo "Script failed with exit code $exit_code" | tee -a "$LOG_FILE"
        echo "Last command: $BASH_COMMAND" | tee -a "$LOG_FILE"
        echo "Stack trace:" | tee -a "$LOG_FILE"
        local frame=0
        while caller $frame; do
            ((frame++))
        done | tee -a "$LOG_FILE"
    fi
    exit $exit_code
}

check_dependencies() {
    local has_missing=0
    local missing_list=""

    for dep in "${DEPENDENCIES[@]}"; do
        if ! dpkg -l | grep -q "^ii.*$dep"; then
            has_missing=1
            missing_list="$missing_list $dep"
        fi
    done

    # Only log if in debug mode
    if [[ $DEBUG -eq 1 ]]; then
        log "DEBUG" "Checking dependencies status..."
    fi

    NEED_DEPENDENCIES=$has_missing
    MISSING_DEPENDENCIES=$missing_list
}

check_repositories() {
    if ! apt-get update &>/dev/null; then
        log "ERROR" "Failed to update package repositories"
        return 1
    fi
    return 0
}

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
    grep -Eq 'vmx|svm' /proc/cpuinfo ||
        log "WARN" "${YELLOW}CPU does not support hardware virtualization (KVM).${NC}"
}

# Install system dependencies
install_dependencies() {
    # First try to install without error trapping to see what's failing
    log "INFO" "Installing missing packages:$MISSING_DEPENDENCIES"

    # Update package list first
    apt-get update

    # Try installing packages one by one to identify problematic packages
    for dep in "${DEPENDENCIES[@]}"; do
        log "INFO" "Installing $dep..."
        if ! apt-get install -y --no-install-recommends "$dep"; then
            error "Failed to install package: $dep"
        fi
    done

    log "INFO" "Package installation completed successfully."
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
    [[ -e /etc/xrdp/startubuntu.sh ]] || cat >/etc/xrdp/startubuntu.sh <<'EOF'
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
    echo "blacklist vmw_vsock_vmci_transport" >/etc/modprobe.d/blacklist-vmw_vsock_vmci_transport.conf
    echo "hv_sock" >/etc/modules-load.d/hv_sock.conf

    # Configure PolicyKit
    cat >/etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla <<'EOF'
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

    # Initialize global variable
    NEED_DEPENDENCIES=0

    # Check root access first
    check_root || error "Root check failed"

    # Check repositories before proceeding
    check_repositories || error "Repository check failed"

    # Check KVM support (non-critical)
    check_kvm_support

    # Check initial dependencies
    check_dependencies
    if [[ $NEED_DEPENDENCIES -eq 1 ]]; then
        log "INFO" "Installing missing dependencies..."
        install_dependencies || error "Failed to install dependencies"
    fi

    # Configure XRDP
    configure_xrdp || error "Failed to configure XRDP"

    # Check if reboot is required
    check_reboot_required

    log "INFO" "${GREEN}Installation and configuration completed successfully.${NC}"
    prompt_reboot
}

main "$@"
