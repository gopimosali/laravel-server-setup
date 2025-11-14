#!/bin/bash

#############################
# Laravel User Setup Script
# Creates a dedicated user for Laravel services and configures permissions
#############################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Display script header
echo "========================================="
echo "  Laravel User Setup"
echo "========================================="
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
else
    OS="unknown"
fi

log_info "Detected OS: $OS"
echo ""

# Prompt for username
echo "========================================="
echo "  User Configuration"
echo "========================================="
echo ""
echo "This script will create a dedicated user for running Laravel services."
echo "This user will:"
echo "  - Run Laravel Supervisor processes (Horizon, Reverb, Pulse, Scheduler)"
echo "  - Own Laravel application files"
echo "  - Have sudo privileges for server management"
echo "  - Be added to the web server group for file access"
echo ""

read -p "Enter the username to create (e.g., laraveladmin, deploy): " USERNAME

# Validate username
if [ -z "$USERNAME" ]; then
    log_error "Username cannot be empty"
    exit 1
fi

# Check if username contains invalid characters
if ! [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    log_error "Invalid username. Must start with lowercase letter or underscore, and contain only lowercase letters, numbers, underscores, and hyphens."
    exit 1
fi

# Check if user already exists
if id "$USERNAME" &>/dev/null; then
    log_warn "User '$USERNAME' already exists!"
    echo ""
    echo "Options:"
    echo "1) Continue and reconfigure existing user"
    echo "2) Exit and choose a different username"
    read -p "Enter choice [1-2]: " user_exists_choice

    if [ "$user_exists_choice" != "1" ]; then
        log_info "Exiting. Please run the script again with a different username."
        exit 0
    fi

    USER_EXISTS=true
    log_info "Reconfiguring existing user '$USERNAME'"
else
    USER_EXISTS=false
    log_info "Will create new user '$USERNAME'"
fi

echo ""

# Detect web server and its user
detect_web_server_user() {
    local web_user=""

    # Try to detect from running processes
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
        # Default to www-data
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
    read -p "Enter the correct web server user (or press Enter to skip): " CUSTOM_WEB_USER
    if [ -n "$CUSTOM_WEB_USER" ]; then
        WEB_SERVER_USER=$CUSTOM_WEB_USER
    fi
fi

echo ""

# Create or update user
if [ "$USER_EXISTS" = false ]; then
    log_info "Creating user '$USERNAME'..."

    # Create user with home directory
    useradd -m -s /bin/bash "$USERNAME"

    if [ $? -eq 0 ]; then
        log_success "User '$USERNAME' created successfully"
    else
        log_error "Failed to create user '$USERNAME'"
        exit 1
    fi

    # Set password
    echo ""
    log_info "Set password for '$USERNAME'"
    passwd "$USERNAME"

    if [ $? -ne 0 ]; then
        log_error "Failed to set password"
        exit 1
    fi
else
    log_info "User '$USERNAME' already exists, skipping creation"
    echo ""
    read -p "Do you want to reset the password for '$USERNAME'? [y/N]: " reset_password
    if [[ "$reset_password" =~ ^[Yy]$ ]]; then
        passwd "$USERNAME"
    fi
fi

echo ""

# Add user to sudo group
log_info "Adding '$USERNAME' to sudo group..."

case $OS in
    ubuntu|debian)
        usermod -aG sudo "$USERNAME"
        SUDO_GROUP="sudo"
        ;;
    centos|rhel|fedora|rocky|almalinux)
        usermod -aG wheel "$USERNAME"
        SUDO_GROUP="wheel"
        ;;
    *)
        # Try sudo first, then wheel
        if getent group sudo &>/dev/null; then
            usermod -aG sudo "$USERNAME"
            SUDO_GROUP="sudo"
        elif getent group wheel &>/dev/null; then
            usermod -aG wheel "$USERNAME"
            SUDO_GROUP="wheel"
        else
            log_warn "Could not find sudo or wheel group"
            SUDO_GROUP="none"
        fi
        ;;
esac

if [ "$SUDO_GROUP" != "none" ]; then
    log_success "User '$USERNAME' added to $SUDO_GROUP group"
else
    log_warn "Could not add user to sudo group"
fi

# Add user to web server group for file access
if id "$WEB_SERVER_USER" &>/dev/null; then
    WEB_SERVER_GROUP=$(id -gn "$WEB_SERVER_USER")
    log_info "Adding '$USERNAME' to web server group '$WEB_SERVER_GROUP'..."
    usermod -aG "$WEB_SERVER_GROUP" "$USERNAME"
    log_success "User '$USERNAME' added to '$WEB_SERVER_GROUP' group"
fi

echo ""

# Update supervisor configuration files
log_info "Updating Supervisor configuration files..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUPERVISOR_FILES=(
    "$SCRIPT_DIR/supervisor-reverb.conf.sample"
    "$SCRIPT_DIR/supervisor-horizon.conf.sample"
    "$SCRIPT_DIR/supervisor-pulse.conf.sample"
    "$SCRIPT_DIR/supervisor-schedule.conf.sample"
)

# Check which files exist
EXISTING_FILES=()
for file in "${SUPERVISOR_FILES[@]}"; do
    if [ -f "$file" ]; then
        EXISTING_FILES+=("$file")
    fi
done

if [ ${#EXISTING_FILES[@]} -eq 0 ]; then
    log_warn "No supervisor configuration files found in $SCRIPT_DIR"
else
    log_info "Found ${#EXISTING_FILES[@]} supervisor configuration file(s)"

    for file in "${EXISTING_FILES[@]}"; do
        filename=$(basename "$file")

        # Create backup
        cp "$file" "$file.backup.$(date +%Y%m%d_%H%M%S)"

        # Update the user line
        sed -i "s/^user=.*/user=$USERNAME/" "$file"

        if [ $? -eq 0 ]; then
            log_success "Updated: $filename"
        else
            log_error "Failed to update: $filename"
        fi
    done
fi

echo ""

# Ask about Laravel application path
echo "========================================="
echo "  Laravel Application Configuration"
echo "========================================="
echo ""
read -p "Do you want to set up file permissions for a Laravel application now? [y/N]: " setup_laravel

if [[ "$setup_laravel" =~ ^[Yy]$ ]]; then
    echo ""
    read -p "Enter the path to your Laravel application (e.g., /var/www/html): " LARAVEL_PATH

    # Trim whitespace
    LARAVEL_PATH=$(echo "$LARAVEL_PATH" | xargs)

    if [ -z "$LARAVEL_PATH" ]; then
        log_warn "No path provided, skipping Laravel setup"
    elif [ ! -d "$LARAVEL_PATH" ]; then
        log_error "Directory does not exist: $LARAVEL_PATH"
    else
        log_info "Setting up Laravel permissions for: $LARAVEL_PATH"
        echo ""

        # Change ownership to new user, but keep web server group
        log_info "Setting ownership to $USERNAME:$WEB_SERVER_GROUP..."
        chown -R "$USERNAME:$WEB_SERVER_GROUP" "$LARAVEL_PATH"

        # Set base permissions
        log_info "Setting base permissions..."
        find "$LARAVEL_PATH" -type d -exec chmod 755 {} \;
        find "$LARAVEL_PATH" -type f -exec chmod 644 {} \;

        # Set writable directories
        log_info "Setting writable permissions..."
        if [ -d "$LARAVEL_PATH/storage" ]; then
            chmod -R 775 "$LARAVEL_PATH/storage"
        fi
        if [ -d "$LARAVEL_PATH/bootstrap/cache" ]; then
            chmod -R 775 "$LARAVEL_PATH/bootstrap/cache"
        fi

        # Make artisan executable
        if [ -f "$LARAVEL_PATH/artisan" ]; then
            chmod 755 "$LARAVEL_PATH/artisan"
        fi

        # Secure .env file
        if [ -f "$LARAVEL_PATH/.env" ]; then
            chmod 640 "$LARAVEL_PATH/.env"
            log_success ".env file secured (640)"
        fi

        log_success "Laravel permissions configured!"
    fi
fi

echo ""

# Display summary
echo "========================================="
echo "  Setup Summary"
echo "========================================="
echo ""
echo "User Details:"
echo "  Username: $USERNAME"
echo "  Home Directory: /home/$USERNAME"
echo "  Sudo Access: Yes (via $SUDO_GROUP group)"
if id "$WEB_SERVER_USER" &>/dev/null; then
    echo "  Web Server Group: $WEB_SERVER_GROUP"
fi
echo ""
echo "Groups:"
id "$USERNAME"
echo ""

# Display next steps
echo "========================================="
echo "  Next Steps"
echo "========================================="
echo ""
echo "1. Verify supervisor configurations have been updated:"
for file in "${EXISTING_FILES[@]}"; do
    echo "   cat $(basename "$file") | grep 'user='"
done
echo ""
echo "2. Copy supervisor configs to /etc/supervisor/conf.d/:"
echo "   sudo cp supervisor-*.conf.sample /etc/supervisor/conf.d/"
echo ""
echo "3. Update paths in supervisor configs for your Laravel installation"
echo ""
echo "4. Reload supervisor:"
echo "   sudo supervisorctl reread"
echo "   sudo supervisorctl update"
echo ""
echo "5. Start Laravel services:"
echo "   sudo supervisorctl start all"
echo ""
echo "6. Switch to the new user to manage Laravel:"
echo "   su - $USERNAME"
echo ""
echo "7. From the new user account, you can run Laravel commands:"
echo "   cd /path/to/laravel"
echo "   php artisan migrate"
echo "   php artisan queue:work"
echo "   etc."
echo ""
log_success "Setup complete!"
