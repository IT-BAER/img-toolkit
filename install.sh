#!/bin/bash
# IMG-Toolkit Installation Script for Debian/Ubuntu
# This script installs all dependencies and sets up IMG-Toolkit as a systemd service

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
PYTHON_VERSION="3.11"

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

check_os() {
    if [[ ! -f /etc/debian_version ]]; then
        log_error "This script is designed for Debian/Ubuntu systems only"
        exit 1
    fi
    log_info "Detected Debian/Ubuntu system"
}

install_system_dependencies() {
    log_info "Installing system dependencies..."
    
    apt-get update
    
    apt-get install -y --no-install-recommends \
        python3 python3-pip python3-venv python3-dev \
        libjpeg-dev libpng-dev libtiff-dev libwebp-dev libopenjp2-7-dev \
        libimagequant-dev libheif-dev liblcms2-dev \
        libfreetype6-dev libharfbuzz-dev libfribidi-dev \
        libxcb1-dev zlib1g-dev libgif-dev ghostscript \
        nodejs npm \
        curl wget git \
        build-essential
    
    # Install pnpm globally
    npm install -g pnpm
    
    log_success "System dependencies installed"
}

create_service_user() {
    if id "$SERVICE_USER" &>/dev/null; then
        log_info "Service user '$SERVICE_USER' already exists"
    else
        log_info "Creating service user '$SERVICE_USER'..."
        useradd --system --no-create-home --shell /bin/false "$SERVICE_USER"
        log_success "Service user created"
    fi
}

setup_installation_directory() {
    log_info "Setting up installation directory at $INSTALL_DIR..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        log_warn "Installation directory already exists. Backing up..."
        mv "$INSTALL_DIR" "${INSTALL_DIR}.backup.$(date +%Y%m%d%H%M%S)"
    fi
    
    mkdir -p "$INSTALL_DIR"
    
    # Copy application files
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cp -r "$SCRIPT_DIR/backend" "$INSTALL_DIR/"
    cp -r "$SCRIPT_DIR/frontend" "$INSTALL_DIR/"
    cp "$SCRIPT_DIR/setup.py" "$INSTALL_DIR/"
    cp "$SCRIPT_DIR/requirements.txt" "$INSTALL_DIR/"
    
    log_success "Application files copied"
}

setup_python_environment() {
    log_info "Setting up Python virtual environment..."
    
    cd "$INSTALL_DIR"
    python3 -m venv venv
    source venv/bin/activate
    
    pip install --upgrade pip
    pip install --no-cache-dir -r requirements.txt
    pip install --no-cache-dir .
    
    deactivate
    
    log_success "Python environment configured"
}

build_frontend() {
    log_info "Building frontend..."
    
    cd "$INSTALL_DIR/frontend"
    pnpm install --frozen-lockfile
    pnpm run build
    
    # Create static site directory and copy built files
    mkdir -p "$INSTALL_DIR/backend/image_converter/presentation/web/static_site"
    cp -r out/. "$INSTALL_DIR/backend/image_converter/presentation/web/static_site/"
    cp -r .next "$INSTALL_DIR/backend/image_converter/presentation/web/static_site/"
    cp -r public "$INSTALL_DIR/backend/image_converter/presentation/web/static_site/"
    
    log_success "Frontend built successfully"
}

create_systemd_service() {
    log_info "Creating systemd service..."
    
    cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=IMG-Toolkit - Image Compression and Conversion Service
After=network.target

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_USER}
WorkingDirectory=${INSTALL_DIR}
Environment="PATH=${INSTALL_DIR}/venv/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=${INSTALL_DIR}/venv/bin/img-toolkit web
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

# Security hardening
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/tmp
ReadOnlyPaths=${INSTALL_DIR}

[Install]
WantedBy=multi-user.target
EOF

    # Set ownership
    chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"
    
    # Reload systemd
    systemctl daemon-reload
    
    log_success "Systemd service created"
}

enable_and_start_service() {
    log_info "Enabling and starting IMG-Toolkit service..."
    
    systemctl enable "$SERVICE_NAME"
    systemctl start "$SERVICE_NAME"
    
    # Wait a moment for the service to start
    sleep 2
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_success "IMG-Toolkit service is running"
    else
        log_error "Service failed to start. Check logs with: journalctl -u $SERVICE_NAME -f"
        exit 1
    fi
}

print_completion_message() {
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}   IMG-Toolkit Installation Complete!       ${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo -e "The service is now running on ${BLUE}http://localhost:5000${NC}"
    echo ""
    echo "Useful commands:"
    echo "  - Check status:    sudo systemctl status $SERVICE_NAME"
    echo "  - View logs:       sudo journalctl -u $SERVICE_NAME -f"
    echo "  - Restart:         sudo systemctl restart $SERVICE_NAME"
    echo "  - Stop:            sudo systemctl stop $SERVICE_NAME"
    echo "  - Start:           sudo systemctl start $SERVICE_NAME"
    echo ""
    echo "Installation directory: $INSTALL_DIR"
    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║       IMG-Toolkit Installation Script                 ║"
    echo "║       Fast, Private Image Compression & Conversion    ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_root
    check_os
    install_system_dependencies
    create_service_user
    setup_installation_directory
    setup_python_environment
    build_frontend
    create_systemd_service
    enable_and_start_service
    print_completion_message
}

# Run main function
main "$@"
