#!/bin/bash
# IMG-Toolkit Unified Installer
# 
# One-liner install:
#   curl -fsSL https://raw.githubusercontent.com/IT-BAER/IMG-Toolkit/main/install.sh | sudo bash
#
# With options:
#   curl -fsSL ... | sudo bash -s -- update
#   curl -fsSL ... | sudo bash -s -- uninstall
#   curl -fsSL ... | sudo bash -s -- status
#
# Local usage (after clone):
#   sudo ./install.sh [install|update|uninstall|status] [-y]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/IT-BAER/IMG-Toolkit.git"
INSTALL_DIR="/opt/img-toolkit"
SERVICE_USER="img-toolkit"
BACKEND_SERVICE="img-toolkit"
FRONTEND_SERVICE="img-toolkit-frontend"
VERSION_FILE="${INSTALL_DIR}/.version"

# Detect if running from pipe (curl | bash) or from local file
if [[ -z "${BASH_SOURCE[0]}" ]] || [[ "${BASH_SOURCE[0]}" == "bash" ]]; then
    RUNNING_FROM_CURL=true
    SCRIPT_DIR=""
else
    RUNNING_FROM_CURL=false
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Mode flags
MODE="install"  # install, update, uninstall, status
FORCE=false     # Skip confirmation prompts

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
    echo "IMG-Toolkit Installer"
    echo ""
    echo "One-liner installation:"
    echo "  curl -fsSL https://raw.githubusercontent.com/IT-BAER/IMG-Toolkit/main/install.sh | sudo bash"
    echo ""
    echo "Usage: $0 [OPTION] [FLAGS]"
    echo ""
    echo "Options:"
    echo "  install     Fresh installation (default)"
    echo "  update      Update existing installation"
    echo "  uninstall   Remove IMG-Toolkit completely"
    echo "  status      Show current installation status"
    echo "  --help      Show this help message"
    echo ""
    echo "Flags:"
    echo "  -y, --yes   Skip confirmation prompts (for automation)"
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

command_exists() {
    command -v "$1" &> /dev/null
}

check_node_version() {
    if command_exists node; then
        NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [[ "$NODE_VERSION" -ge 18 ]]; then
            return 0
        fi
    fi
    return 1
}

# Ensure git is available (needed for curl | bash mode)
ensure_git() {
    if ! command_exists git; then
        log_info "Installing git..."
        apt-get update -qq
        apt-get install -y git 2>/dev/null
    fi
}

# Clone or update repository
setup_repository() {
    log_step "Setting up repository..."
    
    ensure_git
    
    if [[ -d "$INSTALL_DIR/.git" ]]; then
        # Existing git repo - reset local changes and pull
        log_info "Updating existing repository..."
        cd "$INSTALL_DIR"
        git config --global --add safe.directory "$INSTALL_DIR" 2>/dev/null || true
        git checkout -- . 2>/dev/null || true  # Reset any local changes
        git clean -fd 2>/dev/null || true       # Remove untracked files
        git fetch origin
        git reset --hard origin/main
        log_success "Repository updated"
    elif [[ -d "$INSTALL_DIR" ]] && [[ "$MODE" == "update" ]]; then
        # Existing installation but not a git repo - convert it
        log_info "Converting existing installation to git repo..."
        local backup_venv=""
        local backup_node_modules=""
        
        # Backup environments
        if [[ -d "$INSTALL_DIR/venv" ]]; then
            backup_venv="/tmp/img-toolkit-venv-backup-$$"
            mv "$INSTALL_DIR/venv" "$backup_venv"
        fi
        if [[ -d "$INSTALL_DIR/frontend/node_modules" ]]; then
            backup_node_modules="/tmp/img-toolkit-node-modules-backup-$$"
            mv "$INSTALL_DIR/frontend/node_modules" "$backup_node_modules"
        fi
        
        rm -rf "$INSTALL_DIR"
        git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
        
        # Restore environments
        [[ -n "$backup_venv" ]] && mv "$backup_venv" "$INSTALL_DIR/venv"
        [[ -n "$backup_node_modules" ]] && mv "$backup_node_modules" "$INSTALL_DIR/frontend/node_modules"
        
        log_success "Repository cloned"
    else
        # Fresh installation
        if [[ -d "$INSTALL_DIR" ]]; then
            log_warn "Removing existing installation..."
            systemctl stop "$BACKEND_SERVICE" "$FRONTEND_SERVICE" 2>/dev/null || true
            rm -rf "$INSTALL_DIR"
        fi
        
        log_info "Cloning repository..."
        git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
        log_success "Repository cloned"
    fi
    
    cd "$INSTALL_DIR"
}

install_system_dependencies() {
    log_step "Installing system dependencies..."
    
    export DEBIAN_FRONTEND=noninteractive
    
    apt-get update -qq
    
    # Detect freetype package name (Debian 12+ uses libfreetype-dev)
    FREETYPE_PKG="libfreetype-dev"
    if ! apt-cache show libfreetype-dev &>/dev/null; then
        FREETYPE_PKG="libfreetype6-dev"
    fi
    
    apt-get install -y --no-install-recommends \
        python3 python3-pip python3-venv python3-dev \
        libjpeg-dev libpng-dev libtiff-dev libwebp-dev libopenjp2-7-dev \
        libimagequant-dev libheif-dev liblcms2-dev \
        "$FREETYPE_PKG" libharfbuzz-dev libfribidi-dev \
        libxcb1-dev zlib1g-dev libgif-dev ghostscript \
        curl wget git ca-certificates gnupg \
        build-essential nginx 2>/dev/null
    
    # Check if Node.js 18+ is already installed
    if check_node_version; then
        log_info "Node.js $(node -v) already installed"
    else
        log_info "Installing Node.js 20.x LTS..."
        mkdir -p /etc/apt/keyrings
        
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key 2>/dev/null | \
            gpg --batch --yes --dearmor -o /etc/apt/keyrings/nodesource.gpg 2>/dev/null || true
        
        echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
        apt-get update -qq
        apt-get install -y nodejs 2>/dev/null
    fi
    
    # Verify Node.js installation
    if ! check_node_version; then
        log_error "Failed to install Node.js 18+. Please install manually."
        exit 1
    fi
    
    # Install pnpm
    if ! command_exists pnpm; then
        log_info "Installing pnpm..."
        npm install -g pnpm 2>/dev/null || npm install -g pnpm
    else
        log_info "pnpm already installed"
    fi
    
    # Install serve
    if ! command_exists serve; then
        log_info "Installing serve..."
        npm install -g serve 2>/dev/null || npm install -g serve
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
    
    pip install --no-cache-dir -q -r requirements.txt
    pip install --no-cache-dir -q -e .
    
    deactivate
    
    log_success "Python environment ready"
}

build_frontend() {
    log_step "Building frontend..."
    
    cd "$INSTALL_DIR/frontend"
    
    if [[ -f "pnpm-lock.yaml" ]]; then
        pnpm install --frozen-lockfile 2>/dev/null || pnpm install
    else
        pnpm install
    fi
    
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
ExecStart=${INSTALL_DIR}/venv/bin/img-toolkit web
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

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

    chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"
    systemctl daemon-reload
    
    log_success "Systemd services created"
}

setup_nginx() {
    log_step "Setting up nginx reverse proxy..."
    
    if ! command_exists nginx; then
        apt-get install -y nginx 2>/dev/null
    fi
    
    cat > /etc/nginx/sites-available/img-toolkit << 'EOF'
server {
    listen 80;
    server_name _;
    client_max_body_size 100M;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

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

    rm -f /etc/nginx/sites-enabled/default
    ln -sf /etc/nginx/sites-available/img-toolkit /etc/nginx/sites-enabled/
    
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
    {
        echo "installed=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        if [[ -d "$INSTALL_DIR/.git" ]]; then
            echo "commit=$(git -C "$INSTALL_DIR" rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
            echo "branch=$(git -C "$INSTALL_DIR" branch --show-current 2>/dev/null || echo 'unknown')"
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
    echo "  - Update:       curl -fsSL https://raw.githubusercontent.com/IT-BAER/IMG-Toolkit/main/install.sh | sudo bash -s -- update"
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
    
    if [[ "$FORCE" != "true" ]]; then
        read -p "Are you sure? (y/N): " confirm </dev/tty || confirm="n"
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            log_info "Uninstall cancelled"
            exit 0
        fi
    else
        log_info "Force flag set - proceeding with uninstall"
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
                if [[ "$FORCE" != "true" ]]; then
                    read -p "Do you want to reinstall? (y/N): " confirm </dev/tty || confirm="n"
                    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
                        log_info "Use 'update' mode to update existing installation"
                        exit 0
                    fi
                else
                    log_info "Force flag set - proceeding with reinstall"
                fi
            fi
            stop_services
            setup_repository
            install_system_dependencies
            create_service_user
            setup_python_environment
            build_frontend
            create_systemd_services
            setup_nginx
            enable_and_start_services
            save_version
            print_completion_message
            ;;
        update)
            if ! is_installed && [[ ! -d "$INSTALL_DIR" ]]; then
                log_info "IMG-Toolkit is not installed. Performing fresh install..."
                MODE="install"
            fi
            stop_services
            setup_repository
            install_system_dependencies
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
while [[ $# -gt 0 ]]; do
    case "$1" in
        install|update|uninstall|status)
            MODE="$1"
            shift
            ;;
        -y|--yes|--force)
            FORCE=true
            shift
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
done

# For curl | bash, default to non-interactive
if [[ "$RUNNING_FROM_CURL" == "true" ]]; then
    FORCE=true
fi

# Run main function
main "$@"
