#!/bin/bash

#############################
# Laravel Permissions Fixer
# Sets correct ownership and permissions for Laravel application
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
echo "  Laravel Permissions Fixer"
echo "========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Detect current web server
detect_web_server() {
    local detected=""

    if systemctl is-active --quiet apache2 2>/dev/null; then
        detected="apache"
    elif systemctl is-active --quiet nginx 2>/dev/null; then
        detected="nginx"
    fi

    echo "$detected"
}

# Determine appropriate user for web server
get_web_server_user() {
    local web_server=$1
    local os_type=$2

    case $web_server in
        apache)
            if [ "$os_type" == "ubuntu" ] || [ "$os_type" == "debian" ]; then
                echo "www-data"
            elif [ "$os_type" == "centos" ] || [ "$os_type" == "rhel" ] || [ "$os_type" == "fedora" ]; then
                echo "apache"
            else
                echo "www-data"
            fi
            ;;
        nginx)
            if [ "$os_type" == "ubuntu" ] || [ "$os_type" == "debian" ]; then
                echo "www-data"
            elif [ "$os_type" == "centos" ] || [ "$os_type" == "rhel" ] || [ "$os_type" == "fedora" ]; then
                echo "nginx"
            else
                echo "www-data"
            fi
            ;;
        *)
            echo "www-data"
            ;;
    esac
}

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    OS="unknown"
fi

log_info "Detected OS: $OS"

# Detect or prompt for web server
DETECTED_SERVER=$(detect_web_server)

if [ -n "$DETECTED_SERVER" ]; then
    log_info "Detected web server: $DETECTED_SERVER"
    echo ""
    echo "Use detected web server ($DETECTED_SERVER)?"
    echo "1) Yes - Use $DETECTED_SERVER"
    echo "2) No - I'll specify manually"
    read -p "Enter choice [1-2]: " use_detected

    if [ "$use_detected" == "1" ]; then
        WEB_SERVER=$DETECTED_SERVER
    else
        WEB_SERVER=""
    fi
else
    log_warn "Could not auto-detect web server"
    WEB_SERVER=""
fi

# Prompt for web server if not detected or user wants to specify
if [ -z "$WEB_SERVER" ]; then
    echo ""
    echo "Select your web server:"
    echo "1) Apache"
    echo "2) Nginx"
    echo "3) Custom (I'll enter the user manually)"
    read -p "Enter choice [1-3]: " webserver_choice

    case $webserver_choice in
        1)
            WEB_SERVER="apache"
            ;;
        2)
            WEB_SERVER="nginx"
            ;;
        3)
            WEB_SERVER="custom"
            ;;
        *)
            log_error "Invalid choice"
            exit 1
            ;;
    esac
fi

# Determine user
if [ "$WEB_SERVER" == "custom" ]; then
    echo ""
    read -p "Enter the web server username: " CUSTOM_USER
    if [ -z "$CUSTOM_USER" ]; then
        log_error "Username cannot be empty"
        exit 1
    fi
    WEB_USER=$CUSTOM_USER
else
    WEB_USER=$(get_web_server_user "$WEB_SERVER" "$OS")
fi

log_info "Will use user: $WEB_USER"

# Verify user exists
if ! id "$WEB_USER" &>/dev/null; then
    log_error "User '$WEB_USER' does not exist on this system!"
    exit 1
fi

# Get user's primary group
WEB_GROUP=$(id -gn "$WEB_USER")
log_info "Will use group: $WEB_GROUP"

# Prompt for Laravel application path
echo ""
echo "Enter the path to your Laravel application:"
read -p "Path (e.g., /var/www/html): " LARAVEL_PATH

# Trim whitespace
LARAVEL_PATH=$(echo "$LARAVEL_PATH" | xargs)

# Validate path
if [ -z "$LARAVEL_PATH" ]; then
    log_error "Path cannot be empty"
    exit 1
fi

if [ ! -d "$LARAVEL_PATH" ]; then
    log_error "Directory does not exist: $LARAVEL_PATH"
    exit 1
fi

# Check if it's a Laravel application
if [ ! -f "$LARAVEL_PATH/artisan" ]; then
    log_warn "Warning: 'artisan' file not found in $LARAVEL_PATH"
    read -p "This may not be a Laravel application. Continue anyway? [y/N]: " continue_anyway
    if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
        log_info "Aborted by user"
        exit 0
    fi
fi

# Display summary
echo ""
echo "========================================="
echo "  Configuration Summary"
echo "========================================="
echo "Laravel Path: $LARAVEL_PATH"
echo "Owner: $WEB_USER:$WEB_GROUP"
echo ""
echo "The following changes will be made:"
echo "1. Set owner to $WEB_USER:$WEB_GROUP for all files"
echo "2. Set directory permissions to 755"
echo "3. Set file permissions to 644"
echo "4. Set storage/ permissions to 775 (writable)"
echo "5. Set bootstrap/cache/ permissions to 775 (writable)"
echo ""
read -p "Proceed? [y/N]: " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    log_info "Aborted by user"
    exit 0
fi

# Apply permissions
echo ""
log_info "Applying permissions to $LARAVEL_PATH..."

# Change ownership
log_info "Setting ownership to $WEB_USER:$WEB_GROUP..."
chown -R "$WEB_USER:$WEB_GROUP" "$LARAVEL_PATH"
if [ $? -eq 0 ]; then
    log_success "Ownership updated"
else
    log_error "Failed to update ownership"
    exit 1
fi

# Set base permissions (directories: 755, files: 644)
log_info "Setting base permissions..."
find "$LARAVEL_PATH" -type d -exec chmod 755 {} \;
find "$LARAVEL_PATH" -type f -exec chmod 644 {} \;
if [ $? -eq 0 ]; then
    log_success "Base permissions set"
else
    log_error "Failed to set base permissions"
    exit 1
fi

# Set writable directories
log_info "Setting writable permissions for storage and cache..."

if [ -d "$LARAVEL_PATH/storage" ]; then
    chmod -R 775 "$LARAVEL_PATH/storage"
    log_success "storage/ set to 775"
else
    log_warn "storage/ directory not found"
fi

if [ -d "$LARAVEL_PATH/bootstrap/cache" ]; then
    chmod -R 775 "$LARAVEL_PATH/bootstrap/cache"
    log_success "bootstrap/cache/ set to 775"
else
    log_warn "bootstrap/cache/ directory not found"
fi

# Make artisan executable
if [ -f "$LARAVEL_PATH/artisan" ]; then
    chmod 755 "$LARAVEL_PATH/artisan"
    log_success "artisan made executable"
fi

# Verify permissions
echo ""
log_info "Verifying permissions..."
echo ""

# Check storage directory
if [ -d "$LARAVEL_PATH/storage" ]; then
    STORAGE_OWNER=$(stat -c '%U:%G' "$LARAVEL_PATH/storage")
    STORAGE_PERMS=$(stat -c '%a' "$LARAVEL_PATH/storage")
    echo "storage/          : $STORAGE_OWNER ($STORAGE_PERMS)"
fi

# Check bootstrap/cache
if [ -d "$LARAVEL_PATH/bootstrap/cache" ]; then
    CACHE_OWNER=$(stat -c '%U:%G' "$LARAVEL_PATH/bootstrap/cache")
    CACHE_PERMS=$(stat -c '%a' "$LARAVEL_PATH/bootstrap/cache")
    echo "bootstrap/cache/  : $CACHE_OWNER ($CACHE_PERMS)"
fi

# Check artisan
if [ -f "$LARAVEL_PATH/artisan" ]; then
    ARTISAN_OWNER=$(stat -c '%U:%G' "$LARAVEL_PATH/artisan")
    ARTISAN_PERMS=$(stat -c '%a' "$LARAVEL_PATH/artisan")
    echo "artisan           : $ARTISAN_OWNER ($ARTISAN_PERMS)"
fi

echo ""
log_success "Permissions applied successfully!"

# Show additional recommendations
echo ""
echo "========================================="
echo "  Recommendations"
echo "========================================="
echo ""
echo "1. If using Git, add this to .gitignore:"
echo "   /storage/*.key"
echo "   /storage/logs"
echo "   /storage/framework/cache"
echo "   /storage/framework/sessions"
echo "   /storage/framework/views"
echo ""
echo "2. Secure sensitive files:"
echo "   chmod 600 $LARAVEL_PATH/.env"
echo ""
echo "3. If using SELinux (CentOS/RHEL), run:"
echo "   chcon -R -t httpd_sys_rw_content_t $LARAVEL_PATH/storage"
echo "   chcon -R -t httpd_sys_rw_content_t $LARAVEL_PATH/bootstrap/cache"
echo ""
echo "4. Clear Laravel caches after permission changes:"
echo "   cd $LARAVEL_PATH"
echo "   php artisan cache:clear"
echo "   php artisan config:clear"
echo "   php artisan view:clear"
echo ""
log_info "Done!"
