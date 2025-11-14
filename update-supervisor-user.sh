#!/bin/bash

#############################
# Supervisor Config User Updater
# Updates the user in Supervisor config files based on web server
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
echo "  Supervisor Config User Updater"
echo "========================================="
echo ""
echo "This script updates the user in supervisor config files."
echo ""
echo "IMPORTANT: For production setups, it's recommended to create"
echo "a dedicated user for Laravel services instead of using the"
echo "web server user. Use setup-laravel-user.sh for this."
echo ""

# Check if running as root (optional for this script)
if [ "$EUID" -eq 0 ]; then
    log_warn "Running as root. This script can be run as a regular user."
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
            elif [ "$os_type" == "centos" ] || [ "$os_type" == "rhel" ]; then
                echo "apache"
            else
                echo "www-data"
            fi
            ;;
        nginx)
            if [ "$os_type" == "ubuntu" ] || [ "$os_type" == "debian" ]; then
                echo "www-data"
            elif [ "$os_type" == "centos" ] || [ "$os_type" == "rhel" ]; then
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
    echo "Select user configuration method:"
    echo "1) Use web server user (Apache: www-data/apache)"
    echo "2) Use web server user (Nginx: www-data/nginx)"
    echo "3) Use dedicated Laravel user (recommended for production)"
    echo "4) Custom (I'll enter the user manually)"
    read -p "Enter choice [1-4]: " webserver_choice

    case $webserver_choice in
        1)
            WEB_SERVER="apache"
            ;;
        2)
            WEB_SERVER="nginx"
            ;;
        3)
            echo ""
            log_info "Using dedicated Laravel user approach"
            echo "Available users with home directories:"
            ls -1 /home/ 2>/dev/null || echo "  (none found)"
            echo ""
            read -p "Enter the Laravel user (e.g., laraveladmin, deploy): " LARAVEL_USER
            if [ -z "$LARAVEL_USER" ]; then
                log_error "Username cannot be empty"
                exit 1
            fi
            WEB_SERVER="custom"
            CUSTOM_USER=$LARAVEL_USER
            ;;
        4)
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
    read -p "Enter the username to use in supervisor configs: " CUSTOM_USER
    if [ -z "$CUSTOM_USER" ]; then
        log_error "Username cannot be empty"
        exit 1
    fi
    SUPERVISOR_USER=$CUSTOM_USER
else
    SUPERVISOR_USER=$(get_web_server_user "$WEB_SERVER" "$OS")
fi

log_info "Will use user: $SUPERVISOR_USER"

# Verify user exists
if ! id "$SUPERVISOR_USER" &>/dev/null; then
    log_error "User '$SUPERVISOR_USER' does not exist on this system!"
    echo ""
    echo "Available users:"
    cat /etc/passwd | cut -d: -f1 | grep -E "www-data|nginx|apache|http" || echo "  (no common web server users found)"
    echo ""
    read -p "Continue anyway? [y/N]: " continue_anyway
    if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
        log_info "Aborted by user"
        exit 0
    fi
fi

# Find supervisor config files
echo ""
log_info "Looking for supervisor configuration files..."

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
    log_error "No supervisor configuration sample files found in $SCRIPT_DIR"
    exit 1
fi

log_info "Found ${#EXISTING_FILES[@]} configuration file(s)"

# Ask for confirmation
echo ""
echo "The following files will be updated:"
for file in "${EXISTING_FILES[@]}"; do
    echo "  - $(basename "$file")"
done
echo ""
echo "Current user in files: www-data (or other)"
echo "New user: $SUPERVISOR_USER"
echo ""
read -p "Proceed with update? [y/N]: " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    log_info "Aborted by user"
    exit 0
fi

# Update files
echo ""
log_info "Updating configuration files..."

UPDATED_COUNT=0
for file in "${EXISTING_FILES[@]}"; do
    filename=$(basename "$file")

    # Create backup
    cp "$file" "$file.backup"

    # Update the user line using sed
    # This updates lines like: user=www-data or user=nginx or user=apache
    sed -i "s/^user=.*/user=$SUPERVISOR_USER/" "$file"

    if [ $? -eq 0 ]; then
        log_success "Updated: $filename"
        UPDATED_COUNT=$((UPDATED_COUNT + 1))
    else
        log_error "Failed to update: $filename"
        # Restore from backup
        mv "$file.backup" "$file"
    fi
done

echo ""
log_success "Successfully updated $UPDATED_COUNT file(s)"
log_info "Backup files created with .backup extension"

# Show next steps
echo ""
echo "========================================="
echo "  Next Steps"
echo "========================================="
echo ""
echo "1. Review the updated configuration files:"
for file in "${EXISTING_FILES[@]}"; do
    echo "   cat $(basename "$file")"
done
echo ""
echo "2. Copy to /etc/supervisor/conf.d/ (requires sudo):"
echo "   sudo cp supervisor-*.conf.sample /etc/supervisor/conf.d/"
echo ""
echo "3. Edit each file to update paths for your Laravel installation"
echo ""
echo "4. Reload supervisor:"
echo "   sudo supervisorctl reread"
echo "   sudo supervisorctl update"
echo ""
echo "5. Start the services:"
echo "   sudo supervisorctl start all"
echo ""
log_info "Configuration complete!"
