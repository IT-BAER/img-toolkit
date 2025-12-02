#!/bin/bash
# IMG-Toolkit Uninstall Script for Debian/Ubuntu
# This script removes IMG-Toolkit and its systemd service

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/opt/img-toolkit"
SERVICE_USER="img-toolkit"
SERVICE_NAME="img-toolkit"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

stop_service() {
    log_info "Stopping IMG-Toolkit service..."
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        systemctl stop "$SERVICE_NAME"
        log_success "Service stopped"
    else
        log_info "Service is not running"
    fi
}

disable_service() {
    log_info "Disabling IMG-Toolkit service..."
    
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        systemctl disable "$SERVICE_NAME"
        log_success "Service disabled"
    else
        log_info "Service is not enabled"
    fi
}

remove_service_file() {
    log_info "Removing systemd service file..."
    
    if [[ -f /etc/systemd/system/${SERVICE_NAME}.service ]]; then
        rm /etc/systemd/system/${SERVICE_NAME}.service
        systemctl daemon-reload
        log_success "Service file removed"
    else
        log_info "Service file not found"
    fi
}

remove_installation_directory() {
    log_info "Removing installation directory..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf "$INSTALL_DIR"
        log_success "Installation directory removed"
    else
        log_info "Installation directory not found"
    fi
    
    # Also remove any backups
    for backup in ${INSTALL_DIR}.backup.*; do
        if [[ -d "$backup" ]]; then
            log_info "Removing backup: $backup"
            rm -rf "$backup"
        fi
    done
}

remove_service_user() {
    log_info "Removing service user..."
    
    if id "$SERVICE_USER" &>/dev/null; then
        userdel "$SERVICE_USER"
        log_success "Service user removed"
    else
        log_info "Service user not found"
    fi
}

print_completion_message() {
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}   IMG-Toolkit Uninstallation Complete!     ${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo "IMG-Toolkit has been completely removed from your system."
    echo ""
    echo "Note: System dependencies (Python, Node.js, image libraries)"
    echo "were not removed as they may be used by other applications."
    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║       IMG-Toolkit Uninstall Script                    ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${YELLOW}This will completely remove IMG-Toolkit from your system.${NC}"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Uninstallation cancelled"
        exit 0
    fi
    
    check_root
    stop_service
    disable_service
    remove_service_file
    remove_installation_directory
    remove_service_user
    print_completion_message
}

# Run main function
main "$@"
