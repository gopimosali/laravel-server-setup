#!/bin/bash

#############################
# Laravel Application Setup
# Configure a Laravel application with proper permissions and supervisor
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
echo "     Laravel Application Setup"
echo "========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Load server configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/.laravel-server-config"

if [ ! -f "$CONFIG_FILE" ]; then
    log_error "Server configuration not found!"
    echo ""
    echo "Please run ./laravel-server-setup.sh first to configure your server."
    exit 1
fi

# Source configuration
source "$CONFIG_FILE"

log_info "Loaded server configuration"
echo "  Environment: $ENVIRONMENT"
echo "  User: $SUPERVISOR_USER"
echo "  Web Server: $WEB_SERVER_USER ($WEB_SERVER_GROUP)"
echo ""

# Step 1: Laravel Application Path
log_step "Step 1/4: Laravel Application Path"
echo ""

read -p "Enter the full path to your Laravel application: " LARAVEL_PATH

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
        log_info "Aborted"
        exit 0
    fi
fi

log_success "Laravel application found at: $LARAVEL_PATH"
echo ""

# Step 2: Set File Permissions
log_step "Step 2/4: Setting File Permissions"
echo ""

log_info "Setting ownership to $SUPERVISOR_USER:$WEB_SERVER_GROUP..."
chown -R "$SUPERVISOR_USER:$WEB_SERVER_GROUP" "$LARAVEL_PATH"

log_info "Setting base permissions..."
find "$LARAVEL_PATH" -type d -exec chmod 755 {} \;
find "$LARAVEL_PATH" -type f -exec chmod 644 {} \;

log_info "Setting writable directories..."
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

if [ -f "$LARAVEL_PATH/artisan" ]; then
    chmod 755 "$LARAVEL_PATH/artisan"
    log_success "artisan made executable"
fi

if [ -f "$LARAVEL_PATH/.env" ]; then
    chmod 640 "$LARAVEL_PATH/.env"
    log_success ".env file secured (640)"
fi

log_success "Permissions configured!"
echo ""

# Step 3: Laravel Services Selection
log_step "Step 3/4: Laravel Services Configuration"
echo ""

echo "Which Laravel services do you want to configure?"
echo "You can select multiple services (space-separated numbers)"
echo ""
echo "1) Horizon  - Queue worker management"
echo "2) Reverb   - WebSocket server"
echo "3) Pulse    - Application monitoring"
echo "4) Schedule - Task scheduler"
echo ""
read -p "Enter choices (e.g., '1 2 4' or 'all'): " SERVICES_CHOICE

# Parse service selection
SERVICES_TO_SETUP=()

if [[ "$SERVICES_CHOICE" == "all" ]]; then
    SERVICES_TO_SETUP=("horizon" "reverb" "pulse" "schedule")
else
    for choice in $SERVICES_CHOICE; do
        case $choice in
            1) SERVICES_TO_SETUP+=("horizon") ;;
            2) SERVICES_TO_SETUP+=("reverb") ;;
            3) SERVICES_TO_SETUP+=("pulse") ;;
            4) SERVICES_TO_SETUP+=("schedule") ;;
            *) log_warn "Unknown choice: $choice (skipping)" ;;
        esac
    done
fi

if [ ${#SERVICES_TO_SETUP[@]} -eq 0 ]; then
    log_warn "No services selected"
else
    echo ""
    log_info "Selected services: ${SERVICES_TO_SETUP[*]}"
    echo ""

    # Copy and configure supervisor files
    for service in "${SERVICES_TO_SETUP[@]}"; do
        SOURCE_FILE="$SCRIPT_DIR/supervisor-$service.conf.sample"
        DEST_FILE="/etc/supervisor/conf.d/laravel-$service.conf"

        if [ ! -f "$SOURCE_FILE" ]; then
            log_warn "Sample config not found: $SOURCE_FILE"
            continue
        fi

        # Copy file
        cp "$SOURCE_FILE" "$DEST_FILE"

        # Update paths in the config
        sed -i "s|command=php /var/www/html/artisan|command=php $LARAVEL_PATH/artisan|g" "$DEST_FILE"
        sed -i "s|stdout_logfile=/var/www/html/storage/logs|stdout_logfile=$LARAVEL_PATH/storage/logs|g" "$DEST_FILE"

        log_success "Configured: laravel-$service.conf"
    done
fi

echo ""

# Step 4: Start Services
log_step "Step 4/4: Starting Services"
echo ""

read -p "Start Laravel services now? [Y/n]: " start_services

if [[ ! "$start_services" =~ ^[Nn]$ ]]; then
    log_info "Reloading Supervisor configuration..."
    supervisorctl reread
    supervisorctl update

    # Start each selected service
    for service in "${SERVICES_TO_SETUP[@]}"; do
        log_info "Starting laravel-$service..."
        supervisorctl start "laravel-$service:*" 2>/dev/null || log_warn "Failed to start laravel-$service"
    done

    echo ""
    log_info "Service Status:"
    supervisorctl status | grep "laravel-" || log_warn "No Laravel services found"
else
    log_info "Skipping service start. Start manually with:"
    echo "  sudo supervisorctl reread"
    echo "  sudo supervisorctl update"
    echo "  sudo supervisorctl start all"
fi

echo ""

# Display summary
echo "========================================="
echo "  Setup Complete!"
echo "========================================="
echo ""
echo "Application: $LARAVEL_PATH"
echo "Owner: $SUPERVISOR_USER:$WEB_SERVER_GROUP"
echo ""

if [ ${#SERVICES_TO_SETUP[@]} -gt 0 ]; then
    echo "Configured Services:"
    for service in "${SERVICES_TO_SETUP[@]}"; do
        echo "  ✓ laravel-$service"
    done
    echo ""
fi

echo "========================================="
echo "  Useful Commands"
echo "========================================="
echo ""
echo "Check service status:"
echo "  sudo supervisorctl status"
echo ""
echo "View logs:"
echo "  sudo supervisorctl tail -f laravel-horizon:laravel-horizon_00 stdout"
echo ""
echo "Restart services after deployment:"
echo "  php artisan horizon:terminate  # Graceful restart"
echo "  sudo supervisorctl restart laravel-reverb:*"
echo "  sudo supervisorctl restart laravel-pulse:*"
echo ""
echo "Clear Laravel caches:"
echo "  cd $LARAVEL_PATH"
echo "  php artisan cache:clear"
echo "  php artisan config:clear"
echo "  php artisan view:clear"
echo ""

if [ "$USE_DEDICATED_USER" = true ]; then
    echo "Switch to Laravel user:"
    echo "  su - $SUPERVISOR_USER"
    echo ""
fi

log_success "Laravel application configured successfully!"
