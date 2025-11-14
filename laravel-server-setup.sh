#!/bin/bash

#############################
# Laravel Server Setup
# One-time server configuration for Laravel hosting
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
echo "This script configures your server for Laravel hosting."
echo "It will set up users, permissions, and supervisor configs."
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

# Step 1: Environment Selection
log_step "Step 1/5: Environment Configuration"
echo ""
echo "Select your environment:"
echo "1) Production  - Creates dedicated Laravel user (recommended for security)"
echo "2) Development - Uses web server user (simpler, less secure)"
echo ""
read -p "Enter choice [1-2]: " ENV_CHOICE

case $ENV_CHOICE in
    1)
        ENVIRONMENT="production"
        USE_DEDICATED_USER=true
        log_info "Selected: Production environment"
        ;;
    2)
        ENVIRONMENT="development"
        USE_DEDICATED_USER=false
        log_info "Selected: Development environment"
        ;;
    *)
        log_error "Invalid choice"
        exit 1
        ;;
esac

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

echo ""

# Step 2: User Configuration
log_step "Step 2/5: User Configuration"
echo ""

if [ "$USE_DEDICATED_USER" = true ]; then
    # Production: Create dedicated user
    echo "Creating a dedicated user for Laravel services provides:"
    echo "  ✓ Better security isolation"
    echo "  ✓ Clear ownership of processes"
    echo "  ✓ Sudo access for server management"
    echo "  ✓ Separation from web server"
    echo ""

    read -p "Enter username for Laravel services (e.g., laraveladmin, deploy): " LARAVEL_USER

    # Validate username
    if [ -z "$LARAVEL_USER" ]; then
        log_error "Username cannot be empty"
        exit 1
    fi

    if ! [[ "$LARAVEL_USER" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        log_error "Invalid username. Must start with lowercase letter or underscore."
        exit 1
    fi

    # Check if user already exists
    if id "$LARAVEL_USER" &>/dev/null; then
        log_warn "User '$LARAVEL_USER' already exists!"
        echo ""
        read -p "Continue with existing user? [y/N]: " continue_existing
        if [[ ! "$continue_existing" =~ ^[Yy]$ ]]; then
            log_info "Exiting. Please run the script again with a different username."
            exit 0
        fi
        USER_EXISTS=true
    else
        USER_EXISTS=false
    fi

    # Create user if needed
    if [ "$USER_EXISTS" = false ]; then
        log_info "Creating user '$LARAVEL_USER'..."
        useradd -m -s /bin/bash "$LARAVEL_USER"

        if [ $? -eq 0 ]; then
            log_success "User created successfully"
        else
            log_error "Failed to create user"
            exit 1
        fi

        # Set password
        echo ""
        log_info "Set password for '$LARAVEL_USER'"
        passwd "$LARAVEL_USER"

        if [ $? -ne 0 ]; then
            log_error "Failed to set password"
            exit 1
        fi
    else
        log_info "Using existing user '$LARAVEL_USER'"
    fi

    # Add to sudo group
    case $OS in
        ubuntu|debian)
            usermod -aG sudo "$LARAVEL_USER"
            SUDO_GROUP="sudo"
            ;;
        centos|rhel|fedora|rocky|almalinux)
            usermod -aG wheel "$LARAVEL_USER"
            SUDO_GROUP="wheel"
            ;;
        *)
            if getent group sudo &>/dev/null; then
                usermod -aG sudo "$LARAVEL_USER"
                SUDO_GROUP="sudo"
            elif getent group wheel &>/dev/null; then
                usermod -aG wheel "$LARAVEL_USER"
                SUDO_GROUP="wheel"
            fi
            ;;
    esac

    # Add to web server group
    if id "$WEB_SERVER_USER" &>/dev/null; then
        WEB_SERVER_GROUP=$(id -gn "$WEB_SERVER_USER")
        usermod -aG "$WEB_SERVER_GROUP" "$LARAVEL_USER"
        log_success "User '$LARAVEL_USER' configured with sudo and web server access"
    fi

    SUPERVISOR_USER=$LARAVEL_USER

else
    # Development: Use web server user
    log_info "Using web server user: $WEB_SERVER_USER"
    SUPERVISOR_USER=$WEB_SERVER_USER
    WEB_SERVER_GROUP=$(id -gn "$WEB_SERVER_USER")
fi

echo ""

# Step 3: Install Supervisor
log_step "Step 3/5: Supervisor Installation"
echo ""

if command -v supervisorctl &>/dev/null; then
    log_info "Supervisor is already installed"
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
    fi
fi

echo ""

# Step 4: Configure Supervisor Configs
log_step "Step 4/5: Supervisor Configuration"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Update supervisor config files with the correct user
SUPERVISOR_FILES=(
    "$SCRIPT_DIR/supervisor-reverb.conf.sample"
    "$SCRIPT_DIR/supervisor-horizon.conf.sample"
    "$SCRIPT_DIR/supervisor-pulse.conf.sample"
    "$SCRIPT_DIR/supervisor-schedule.conf.sample"
)

EXISTING_FILES=()
for file in "${SUPERVISOR_FILES[@]}"; do
    if [ -f "$file" ]; then
        EXISTING_FILES+=("$file")
    fi
done

if [ ${#EXISTING_FILES[@]} -eq 0 ]; then
    log_warn "No supervisor configuration files found in $SCRIPT_DIR"
else
    log_info "Updating supervisor configuration files..."

    for file in "${EXISTING_FILES[@]}"; do
        filename=$(basename "$file")

        # Create backup
        cp "$file" "$file.backup.$(date +%Y%m%d_%H%M%S)"

        # Update the user line
        sed -i "s/^user=.*/user=$SUPERVISOR_USER/" "$file"

        if [ $? -eq 0 ]; then
            log_success "Updated: $filename"
        else
            log_error "Failed to update: $filename"
        fi
    done
fi

echo ""

# Step 5: Create config file for laravel-app-setup.sh
log_step "Step 5/5: Saving Configuration"
echo ""

CONFIG_FILE="$SCRIPT_DIR/.laravel-server-config"

cat > "$CONFIG_FILE" << EOF
# Laravel Server Configuration
# Generated on $(date)
# DO NOT EDIT MANUALLY

ENVIRONMENT=$ENVIRONMENT
SUPERVISOR_USER=$SUPERVISOR_USER
WEB_SERVER_USER=$WEB_SERVER_USER
WEB_SERVER_GROUP=$WEB_SERVER_GROUP
USE_DEDICATED_USER=$USE_DEDICATED_USER
OS=$OS
OS_VERSION=$OS_VERSION
EOF

chmod 600 "$CONFIG_FILE"
log_success "Configuration saved to $CONFIG_FILE"

echo ""
echo "========================================="
echo "  Setup Complete!"
echo "========================================="
echo ""
echo "Configuration Summary:"
echo "  Environment: $ENVIRONMENT"
echo "  Supervisor User: $SUPERVISOR_USER"
echo "  Web Server User: $WEB_SERVER_USER"
echo "  Web Server Group: $WEB_SERVER_GROUP"
echo ""

if [ "$USE_DEDICATED_USER" = true ]; then
    echo "User Details:"
    echo "  Username: $SUPERVISOR_USER"
    echo "  Home Directory: /home/$SUPERVISOR_USER"
    echo "  Groups: $(id -nG "$SUPERVISOR_USER")"
    echo ""
fi

echo "========================================="
echo "  Next Steps"
echo "========================================="
echo ""
echo "1. Install Supervisor configs (if not already done):"
echo "   sudo cp supervisor-*.conf.sample /etc/supervisor/conf.d/"
echo ""
echo "2. Set up your Laravel application:"
echo "   sudo ./laravel-app-setup.sh"
echo ""
echo "3. The app setup script will:"
echo "   - Configure permissions for your Laravel app"
echo "   - Update supervisor configs with app paths"
echo "   - Start Laravel services (Horizon, Reverb, etc.)"
echo ""

if [ "$USE_DEDICATED_USER" = true ]; then
    echo "4. Switch to Laravel user for management:"
    echo "   su - $SUPERVISOR_USER"
    echo ""
fi

log_success "Server setup complete! Ready for Laravel applications."
