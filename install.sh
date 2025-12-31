#!/bin/bash
# IMG-Toolkit Installation Script for Debian/Ubuntu
# This script installs all dependencies and sets up IMG-Toolkit as a systemd service
# Supports: install, update, uninstall, status

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/opt/img-toolkit"
SERVICE_USER="img-toolkit"
BACKEND_SERVICE="img-toolkit"
FRONTEND_SERVICE="img-toolkit-frontend"
VERSION_FILE="${INSTALL_DIR}/.version"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Mode flags
MODE="install"  # install, update, uninstall, status

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

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

print_usage() {
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  install     Fresh installation (default)"
    echo "  update      Update existing installation"
    echo "  uninstall   Remove IMG-Toolkit completely"
    echo "  status      Show current installation status"
    echo "  --help      Show this help message"
    echo ""
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

is_installed() {
    [[ -d "$INSTALL_DIR" ]] && [[ -d "${INSTALL_DIR}/venv" ]]
}

get_installed_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        cat "$VERSION_FILE"
    else
        echo "unknown"
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check Node.js version (need 18+)
check_node_version() {
    if command_exists node; then
        NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [[ "$NODE_VERSION" -ge 18 ]]; then
            return 0
        fi
    fi
    return 1
}

install_system_dependencies() {
    log_step "Installing system dependencies..."
    
    # Use non-interactive mode for apt
    export DEBIAN_FRONTEND=noninteractive
    
    apt-get update -qq
    
    # Install base dependencies
    apt-get install -y --no-install-recommends \
        python3 python3-pip python3-venv python3-dev \
        libjpeg-dev libpng-dev libtiff-dev libwebp-dev libopenjp2-7-dev \
        libimagequant-dev libheif-dev liblcms2-dev \
        libfreetype6-dev libharfbuzz-dev libfribidi-dev \
        libxcb1-dev zlib1g-dev libgif-dev ghostscript \
        curl wget git ca-certificates gnupg \
        build-essential 2>/dev/null
    
    # Check if Node.js 18+ is already installed
    if check_node_version; then
        log_info "Node.js $(node -v) already installed"
    else
        log_info "Installing Node.js 20.x LTS..."
        mkdir -p /etc/apt/keyrings
        
        # Download and install GPG key non-interactively
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key 2>/dev/null | \
            gpg --batch --yes --dearmor -o /etc/apt/keyrings/nodesource.gpg 2>/dev/null
        
        echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
        apt-get update -qq
        apt-get install -y nodejs 2>/dev/null
    fi
    
    # Install pnpm if not present
    if ! command_exists pnpm; then
        log_info "Installing pnpm..."
        npm install -g pnpm 2>/dev/null
    else
        log_info "pnpm already installed"
    fi
    
    # Install serve for static file hosting
    if ! command_exists serve; then
        log_info "Installing serve..."
        npm install -g serve 2>/dev/null
    fi
    
    log_success "System dependencies ready"
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

stop_services() {
    log_info "Stopping services..."
    systemctl stop "$BACKEND_SERVICE" 2>/dev/null || true
    systemctl stop "$FRONTEND_SERVICE" 2>/dev/null || true
}

setup_installation_directory() {
    log_step "Setting up installation directory..."
    
    if [[ "$MODE" == "update" ]] && [[ -d "$INSTALL_DIR" ]]; then
        # For updates, preserve venv and just update source files
        log_info "Updating existing installation..."
        
        # Backup current version
        if [[ -f "$VERSION_FILE" ]]; then
            cp "$VERSION_FILE" "${VERSION_FILE}.bak"
        fi
        
        # Update backend files
        rm -rf "$INSTALL_DIR/backend"
        cp -r "$SCRIPT_DIR/backend" "$INSTALL_DIR/"
        
        # Update frontend source (preserve node_modules)
        if [[ -d "$INSTALL_DIR/frontend/node_modules" ]]; then
            log_info "Preserving frontend node_modules..."
            mv "$INSTALL_DIR/frontend/node_modules" /tmp/img-toolkit-node-modules-backup
        fi
        rm -rf "$INSTALL_DIR/frontend"
        cp -r "$SCRIPT_DIR/frontend" "$INSTALL_DIR/"
        if [[ -d "/tmp/img-toolkit-node-modules-backup" ]]; then
            mv /tmp/img-toolkit-node-modules-backup "$INSTALL_DIR/frontend/node_modules"
        fi
        
        # Update other files
        cp "$SCRIPT_DIR/setup.py" "$INSTALL_DIR/"
        cp "$SCRIPT_DIR/requirements.txt" "$INSTALL_DIR/"
    else
        # Fresh installation
        if [[ -d "$INSTALL_DIR" ]]; then
            log_warn "Removing existing installation..."
            rm -rf "$INSTALL_DIR"
        fi
        
        mkdir -p "$INSTALL_DIR"
        
        # Copy all application files
        cp -r "$SCRIPT_DIR/backend" "$INSTALL_DIR/"
        cp -r "$SCRIPT_DIR/frontend" "$INSTALL_DIR/"
        cp "$SCRIPT_DIR/setup.py" "$INSTALL_DIR/"
        cp "$SCRIPT_DIR/requirements.txt" "$INSTALL_DIR/"
    fi
    
    log_success "Application files ready"
}

setup_python_environment() {
    log_step "Setting up Python environment..."
    
    cd "$INSTALL_DIR"
    
    if [[ "$MODE" == "update" ]] && [[ -d "venv" ]]; then
        log_info "Updating existing Python environment..."
        source venv/bin/activate
    else
        log_info "Creating new Python virtual environment..."
        python3 -m venv venv
        source venv/bin/activate
        pip install --upgrade pip -q
    fi
    
    # Install/update requirements
    pip install --no-cache-dir -q -r requirements.txt
    pip install --no-cache-dir -q -e .
    
    deactivate
    
    log_success "Python environment ready"
}

build_frontend() {
    log_step "Building frontend..."
    
    cd "$INSTALL_DIR/frontend"
    
    # Install dependencies (use frozen lockfile if available)
    if [[ -f "pnpm-lock.yaml" ]]; then
        pnpm install --frozen-lockfile 2>/dev/null || pnpm install
    else
        pnpm install
    fi
    
    # Build with memory limit for low-memory systems
    export NODE_OPTIONS="--max-old-space-size=512"
    pnpm run build
    
    log_success "Frontend built successfully"
}

create_systemd_services() {
    log_step "Creating systemd services..."
    
    # Backend service
    cat > /etc/systemd/system/${BACKEND_SERVICE}.service << EOF
[Unit]
Description=IMG-Toolkit Backend - Image Compression API
After=network.target

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_USER}
WorkingDirectory=${INSTALL_DIR}
Environment="PATH=${INSTALL_DIR}/venv/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=${INSTALL_DIR}/venv/bin/image-converter web
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

    # Frontend service
    cat > /etc/systemd/system/${FRONTEND_SERVICE}.service << EOF
[Unit]
Description=IMG-Toolkit Frontend - Static File Server
After=network.target ${BACKEND_SERVICE}.service
Wants=${BACKEND_SERVICE}.service

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_USER}
WorkingDirectory=${INSTALL_DIR}/frontend
ExecStart=/usr/bin/npx serve out -l 3000
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # Set ownership
    chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"
    
    # Reload systemd
    systemctl daemon-reload
    
    log_success "Systemd services created"
}

setup_nginx() {
    log_step "Setting up nginx reverse proxy..."
    
    # Install nginx if not present
    if ! command_exists nginx; then
        apt-get install -y nginx 2>/dev/null
    fi
    
    # Create nginx config
    cat > /etc/nginx/sites-available/img-toolkit << 'EOF'
server {
    listen 80;
    server_name _;
    client_max_body_size 100M;

    # Frontend - serve static files
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Backend API
    location /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 1800;
        proxy_send_timeout 1800;
    }
}
EOF

    # Enable site
    rm -f /etc/nginx/sites-enabled/default
    ln -sf /etc/nginx/sites-available/img-toolkit /etc/nginx/sites-enabled/
    
    # Test and reload nginx
    nginx -t && systemctl enable nginx && systemctl restart nginx
    
    log_success "Nginx configured"
}

enable_and_start_services() {
    log_step "Enabling and starting services..."
    
    systemctl enable "$BACKEND_SERVICE" "$FRONTEND_SERVICE"
    systemctl start "$BACKEND_SERVICE"
    sleep 2
    systemctl start "$FRONTEND_SERVICE"
    sleep 2
    
    if systemctl is-active --quiet "$BACKEND_SERVICE" && systemctl is-active --quiet "$FRONTEND_SERVICE"; then
        log_success "All services are running"
    else
        log_warn "Some services may not be running. Check with: systemctl status $BACKEND_SERVICE $FRONTEND_SERVICE"
    fi
}

save_version() {
    # Save installation timestamp and git info if available
    {
        echo "installed=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        if [[ -d "$SCRIPT_DIR/.git" ]]; then
            echo "commit=$(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
            echo "branch=$(git -C "$SCRIPT_DIR" branch --show-current 2>/dev/null || echo 'unknown')"
        fi
    } > "$VERSION_FILE"
    chown "$SERVICE_USER:$SERVICE_USER" "$VERSION_FILE"
}

print_completion_message() {
    echo ""
    echo -e "${GREEN}============================================${NC}"
    if [[ "$MODE" == "update" ]]; then
        echo -e "${GREEN}   IMG-Toolkit Update Complete!             ${NC}"
    else
        echo -e "${GREEN}   IMG-Toolkit Installation Complete!       ${NC}"
    fi
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo -e "The application is running at: ${BLUE}http://localhost${NC}"
    echo ""
    echo "Services:"
    echo "  - Backend API:  http://localhost:5000"
    echo "  - Frontend:     http://localhost:3000"
    echo "  - Nginx proxy:  http://localhost (port 80)"
    echo ""
    echo "Useful commands:"
    echo "  - Status:       sudo systemctl status $BACKEND_SERVICE $FRONTEND_SERVICE nginx"
    echo "  - Logs:         sudo journalctl -u $BACKEND_SERVICE -u $FRONTEND_SERVICE -f"
    echo "  - Restart:      sudo systemctl restart $BACKEND_SERVICE $FRONTEND_SERVICE"
    echo "  - Update:       sudo $0 update"
    echo ""
    echo "Installation directory: $INSTALL_DIR"
    echo ""
}

show_status() {
    echo ""
    echo -e "${BLUE}IMG-Toolkit Status${NC}"
    echo "===================="
    
    if is_installed; then
        echo -e "Installation: ${GREEN}Found${NC}"
        echo "Directory: $INSTALL_DIR"
        echo ""
        echo "Version info:"
        if [[ -f "$VERSION_FILE" ]]; then
            cat "$VERSION_FILE" | sed 's/^/  /'
        else
            echo "  unknown"
        fi
    else
        echo -e "Installation: ${RED}Not found${NC}"
        return
    fi
    
    echo ""
    echo "Services:"
    
    for svc in "$BACKEND_SERVICE" "$FRONTEND_SERVICE" "nginx"; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            echo -e "  $svc: ${GREEN}running${NC}"
        elif systemctl is-enabled --quiet "$svc" 2>/dev/null; then
            echo -e "  $svc: ${YELLOW}stopped${NC}"
        else
            echo -e "  $svc: ${RED}not configured${NC}"
        fi
    done
    
    echo ""
}

do_uninstall() {
    echo ""
    log_warn "This will completely remove IMG-Toolkit!"
    read -p "Are you sure? (y/N): " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "Uninstall cancelled"
        exit 0
    fi
    
    log_info "Stopping and disabling services..."
    systemctl stop "$BACKEND_SERVICE" "$FRONTEND_SERVICE" 2>/dev/null || true
    systemctl disable "$BACKEND_SERVICE" "$FRONTEND_SERVICE" 2>/dev/null || true
    
    log_info "Removing service files..."
    rm -f /etc/systemd/system/${BACKEND_SERVICE}.service
    rm -f /etc/systemd/system/${FRONTEND_SERVICE}.service
    rm -f /etc/nginx/sites-enabled/img-toolkit
    rm -f /etc/nginx/sites-available/img-toolkit
    systemctl daemon-reload
    systemctl reload nginx 2>/dev/null || true
    
    log_info "Removing installation directory..."
    rm -rf "$INSTALL_DIR"
    
    log_info "Removing service user..."
    userdel "$SERVICE_USER" 2>/dev/null || true
    
    log_success "IMG-Toolkit has been uninstalled"
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
    
    case "$MODE" in
        install)
            if is_installed; then
                log_warn "IMG-Toolkit is already installed."
                read -p "Do you want to reinstall? (y/N): " confirm
                if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
                    log_info "Use '$0 update' to update existing installation"
                    exit 0
                fi
            fi
            stop_services
            install_system_dependencies
            create_service_user
            setup_installation_directory
            setup_python_environment
            build_frontend
            create_systemd_services
            setup_nginx
            enable_and_start_services
            save_version
            print_completion_message
            ;;
        update)
            if ! is_installed; then
                log_error "IMG-Toolkit is not installed. Use '$0 install' first."
                exit 1
            fi
            stop_services
            install_system_dependencies
            setup_installation_directory
            setup_python_environment
            build_frontend
            create_systemd_services
            setup_nginx
            enable_and_start_services
            save_version
            print_completion_message
            ;;
        uninstall)
            do_uninstall
            ;;
        status)
            show_status
            ;;
        *)
            log_error "Unknown mode: $MODE"
            print_usage
            exit 1
            ;;
    esac
}

# Parse arguments
case "${1:-install}" in
    install|update|uninstall|status)
        MODE="$1"
        ;;
    --help|-h)
        print_usage
        exit 0
        ;;
    *)
        log_error "Unknown option: $1"
        print_usage
        exit 1
        ;;
esac

# Run main function
main "$@"
