#!/bin/bash

#############################
# Laravel Server Setup
# One-time server preparation for Laravel hosting
#############################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${BLUE}[SUCCESS]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Display banner
clear
echo "========================================="
echo "     Laravel Server Setup"
echo "========================================="
echo ""
echo "This script prepares your server for Laravel hosting."
echo "It will install Supervisor and detect your web server."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VERSION=$VERSION_ID
else
    OS="unknown"
fi

log_info "Detected OS: $OS $OS_VERSION"
echo ""

# Check PHP installation
log_step "Checking PHP Installation"
echo ""

if command -v php &>/dev/null; then
    PHP_VERSION=$(php -v | head -n 1 | cut -d " " -f 2 | cut -d "." -f 1-2)
    log_info "PHP is installed: $(php -v | head -n 1)"

    # Check for common required extensions
    log_info "Checking PHP extensions..."
    MISSING_EXTENSIONS=()
    REQUIRED_EXTENSIONS=("curl" "mbstring" "xml" "zip" "bcmath" "pdo")

    for ext in "${REQUIRED_EXTENSIONS[@]}"; do
        if ! php -m | grep -q "^$ext$"; then
            MISSING_EXTENSIONS+=("$ext")
        fi
    done

    if [ ${#MISSING_EXTENSIONS[@]} -gt 0 ]; then
        log_warn "Missing recommended extensions: ${MISSING_EXTENSIONS[*]}"
        echo "Consider installing them for full Laravel compatibility"
    else
        log_success "All essential PHP extensions are installed"
    fi
else
    log_warn "PHP is not installed!"
    echo ""
    echo "Laravel requires PHP 8.2 or higher with several extensions."
    echo ""

    SCRIPT_DIR_CHECK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR_CHECK/setup-php84.sh" ]; then
        read -p "Would you like to run setup-php84.sh now? [Y/n]: " install_php
        if [[ ! "$install_php" =~ ^[Nn]$ ]]; then
            log_info "Running PHP installation script..."
            chmod +x "$SCRIPT_DIR_CHECK/setup-php84.sh"
            "$SCRIPT_DIR_CHECK/setup-php84.sh"

            if [ $? -ne 0 ]; then
                log_error "PHP installation failed"
                exit 1
            fi

            log_success "PHP installation completed"
        else
            log_warn "Skipping PHP installation"
            log_info "Note: You must install PHP manually before deploying Laravel applications"
        fi
    else
        log_error "setup-php84.sh not found in $SCRIPT_DIR_CHECK"
        log_info "Please install PHP 8.2+ and required extensions manually"
        echo ""
        read -p "Continue anyway? [y/N]: " continue_without_php
        if [[ ! "$continue_without_php" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

echo ""

# Detect web server and its user
detect_web_server_user() {
    local web_user=""

    if systemctl is-active --quiet apache2 2>/dev/null; then
        if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
            web_user="www-data"
        else
            web_user="apache"
        fi
    elif systemctl is-active --quiet nginx 2>/dev/null; then
        if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
            web_user="www-data"
        else
            web_user="nginx"
        fi
    else
        web_user="www-data"
    fi

    echo "$web_user"
}

WEB_SERVER_USER=$(detect_web_server_user)
log_info "Detected web server user: $WEB_SERVER_USER"

# Verify web server user exists
if ! id "$WEB_SERVER_USER" &>/dev/null; then
    log_warn "Web server user '$WEB_SERVER_USER' does not exist"
    echo ""
    read -p "Enter the correct web server user: " CUSTOM_WEB_USER
    if [ -n "$CUSTOM_WEB_USER" ]; then
        WEB_SERVER_USER=$CUSTOM_WEB_USER
    fi
fi

WEB_SERVER_GROUP=$(id -gn "$WEB_SERVER_USER" 2>/dev/null || echo "www-data")

echo ""

# Install Supervisor
log_step "Installing Supervisor"
echo ""

if command -v supervisorctl &>/dev/null; then
    log_info "Supervisor is already installed"
    SUPERVISOR_VERSION=$(supervisorctl version 2>/dev/null || echo "unknown")
    log_info "Version: $SUPERVISOR_VERSION"
else
    read -p "Supervisor is not installed. Install now? [Y/n]: " install_supervisor
    if [[ ! "$install_supervisor" =~ ^[Nn]$ ]]; then
        log_info "Installing Supervisor..."

        case $OS in
            ubuntu|debian)
                apt-get update
                apt-get install -y supervisor
                systemctl enable supervisor
                systemctl start supervisor
                ;;
            centos|rhel|fedora|rocky|almalinux)
                yum install -y supervisor
                systemctl enable supervisord
                systemctl start supervisord
                ;;
            *)
                log_error "Unsupported OS for automatic Supervisor installation"
                log_info "Please install Supervisor manually and run this script again"
                exit 1
                ;;
        esac

        log_success "Supervisor installed and started"
    else
        log_warn "Skipping Supervisor installation"
        log_info "Note: Supervisor is required for Laravel services (Horizon, Reverb, etc.)"
    fi
fi

echo ""

# Save server configuration
log_step "Saving Server Configuration"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/.laravel-server-config"

cat > "$CONFIG_FILE" << EOF
# Laravel Server Configuration
# Generated on $(date)

OS=$OS
OS_VERSION=$OS_VERSION
WEB_SERVER_USER=$WEB_SERVER_USER
WEB_SERVER_GROUP=$WEB_SERVER_GROUP
EOF

chmod 600 "$CONFIG_FILE"
log_success "Configuration saved to $CONFIG_FILE"

echo ""
echo "========================================="
echo "  Server Setup Complete!"
echo "========================================="
echo ""
echo "Server Information:"
echo "  OS: $OS $OS_VERSION"
if command -v php &>/dev/null; then
    echo "  PHP: $(php -v | head -n 1 | cut -d ' ' -f 2)"
else
    echo "  PHP: Not installed"
fi
echo "  Web Server User: $WEB_SERVER_USER"
echo "  Web Server Group: $WEB_SERVER_GROUP"
if command -v supervisorctl &>/dev/null; then
    echo "  Supervisor: Installed"
else
    echo "  Supervisor: Not installed"
fi
echo ""
echo "========================================="
echo "  Next Steps"
echo "========================================="
echo ""
echo "Deploy your Laravel application:"
echo ""
echo "Option 1 (Recommended):"
echo "  1. Switch to your user account:"
echo "     su - yourusername"
echo ""
echo "  2. Navigate to setup directory:"
echo "     cd /root/php-server-setup  # or wherever you cloned this"
echo ""
echo "  3. Run app setup with sudo:"
echo "     sudo ./app-setup.sh"
echo ""
echo "  Benefits: Uses your SSH keys, clones to ~/your-app automatically"
echo ""
echo "Option 2:"
echo "  Run directly as root:"
echo "     sudo ./app-setup.sh"
echo ""
echo "The app setup script will:"
echo "  • Configure user and permissions for your Laravel app"
echo "  • Clone from Git or use local directory"
echo "  • Set up supervisor services (Horizon, Reverb, Pulse, Schedule)"
echo ""

log_success "Server ready for Laravel applications!"
