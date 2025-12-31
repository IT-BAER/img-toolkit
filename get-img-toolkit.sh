#!/bin/bash
# IMG-Toolkit Bootstrap Installer
# Run with: curl -fsSL https://raw.githubusercontent.com/IT-BAER/IMG-Toolkit/main/get-img-toolkit.sh | sudo bash
#
# Or with options:
#   curl -fsSL ... | sudo bash -s -- update
#   curl -fsSL ... | sudo bash -s -- uninstall
#   curl -fsSL ... | sudo bash -s -- status

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

REPO_URL="https://github.com/IT-BAER/IMG-Toolkit.git"
INSTALL_DIR="/opt/img-toolkit"
TMP_DIR="/tmp/img-toolkit-install"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Check OS
if [[ ! -f /etc/debian_version ]]; then
    log_error "This script is designed for Debian/Ubuntu systems only"
    exit 1
fi

# Parse mode
MODE="${1:-install}"
case "$MODE" in
    install|update|uninstall|status)
        ;;
    --help|-h)
        echo ""
        echo "IMG-Toolkit Installer"
        echo ""
        echo "Usage: curl -fsSL https://raw.githubusercontent.com/IT-BAER/IMG-Toolkit/main/get-img-toolkit.sh | sudo bash"
        echo ""
        echo "Options (pass after -s --):"
        echo "  install     Fresh installation (default)"
        echo "  update      Update existing installation"  
        echo "  uninstall   Remove IMG-Toolkit completely"
        echo "  status      Show current installation status"
        echo ""
        exit 0
        ;;
    *)
        log_error "Unknown option: $MODE"
        echo "Valid options: install, update, uninstall, status, --help"
        exit 1
        ;;
esac

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════╗"
echo "║       IMG-Toolkit Bootstrap Installer                 ║"
echo "║       Fast, Private Image Compression & Conversion    ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Install git if not available
if ! command -v git &> /dev/null; then
    log_info "Installing git..."
    apt-get update -qq
    apt-get install -y git 2>/dev/null
fi

# Handle different modes
case "$MODE" in
    install|update)
        # Clone/update repository
        if [[ -d "$INSTALL_DIR/.git" ]]; then
            log_info "Updating repository..."
            cd "$INSTALL_DIR"
            git fetch origin
            git reset --hard origin/main
        else
            log_info "Cloning repository..."
            rm -rf "$TMP_DIR"
            git clone --depth 1 "$REPO_URL" "$TMP_DIR"
            
            # For fresh install, remove existing dir if it exists
            if [[ -d "$INSTALL_DIR" ]] && [[ "$MODE" == "install" ]]; then
                log_warn "Removing existing installation..."
                # Stop services first
                systemctl stop img-toolkit img-toolkit-frontend 2>/dev/null || true
                rm -rf "$INSTALL_DIR"
            fi
            
            # Move to install dir
            if [[ ! -d "$INSTALL_DIR" ]]; then
                mv "$TMP_DIR" "$INSTALL_DIR"
            else
                # Update mode - preserve venv and node_modules
                log_info "Preserving existing environments..."
                [[ -d "$INSTALL_DIR/venv" ]] && mv "$INSTALL_DIR/venv" /tmp/img-toolkit-venv-backup
                [[ -d "$INSTALL_DIR/frontend/node_modules" ]] && mv "$INSTALL_DIR/frontend/node_modules" /tmp/img-toolkit-node-modules-backup
                
                rm -rf "$INSTALL_DIR"
                mv "$TMP_DIR" "$INSTALL_DIR"
                
                [[ -d "/tmp/img-toolkit-venv-backup" ]] && mv /tmp/img-toolkit-venv-backup "$INSTALL_DIR/venv"
                [[ -d "/tmp/img-toolkit-node-modules-backup" ]] && mv /tmp/img-toolkit-node-modules-backup "$INSTALL_DIR/frontend/node_modules"
            fi
        fi
        
        cd "$INSTALL_DIR"
        
        # Run the main installer
        chmod +x install.sh
        ./install.sh "$MODE"
        ;;
        
    uninstall)
        if [[ -f "$INSTALL_DIR/install.sh" ]]; then
            cd "$INSTALL_DIR"
            ./install.sh uninstall
        else
            log_error "IMG-Toolkit is not installed or install.sh not found"
            exit 1
        fi
        ;;
        
    status)
        if [[ -f "$INSTALL_DIR/install.sh" ]]; then
            cd "$INSTALL_DIR"
            ./install.sh status
        else
            log_error "IMG-Toolkit is not installed"
            exit 1
        fi
        ;;
esac
