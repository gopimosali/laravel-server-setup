#!/bin/bash

#############################
# Laravel Application Setup
# Complete Laravel app deployment with user management and services
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
SERVER_CONFIG_FILE="$SCRIPT_DIR/.laravel-server-config"

if [ ! -f "$SERVER_CONFIG_FILE" ]; then
    log_error "Server configuration not found!"
    echo ""
    echo "Please run ./laravel-server-setup.sh first to prepare your server."
    exit 1
fi

# Source server configuration
source "$SERVER_CONFIG_FILE"

log_info "Loaded server configuration"
echo "  OS: $OS"
echo "  Web Server User: $WEB_SERVER_USER ($WEB_SERVER_GROUP)"
echo ""

# Step 1: User Configuration
log_step "Step 1/6: User Configuration"
echo ""

# Check for previous app configuration
APP_CONFIG_FILE="$SCRIPT_DIR/.laravel-app-config"
PREVIOUS_USER=""

if [ -f "$APP_CONFIG_FILE" ]; then
    source "$APP_CONFIG_FILE"
    if [ -n "$SUPERVISOR_USER" ]; then
        PREVIOUS_USER=$SUPERVISOR_USER
        log_info "Previous configuration found: User '$PREVIOUS_USER'"
        echo ""
        read -p "Reuse user '$PREVIOUS_USER'? [Y/n]: " reuse_user
        if [[ ! "$reuse_user" =~ ^[Nn]$ ]]; then
            # Verify user still exists
            if id "$PREVIOUS_USER" &>/dev/null; then
                FINAL_USER=$PREVIOUS_USER
                USER_SELECTED=true
                log_success "Reusing user: $FINAL_USER"
            else
                log_warn "User '$PREVIOUS_USER' no longer exists"
                USER_SELECTED=false
            fi
        else
            USER_SELECTED=false
        fi
        echo ""
    else
        USER_SELECTED=false
    fi
else
    USER_SELECTED=false
fi

# Prompt for user selection if not reusing
if [ "$USER_SELECTED" = false ]; then
    echo "Select user configuration:"
    echo ""
    echo "1) Development - Use web server user ($WEB_SERVER_USER)"
    echo "2) Production  - Create new dedicated user"
    echo "3) Production  - Use existing user"
    echo ""
    read -p "Enter choice [1-3]: " USER_CHOICE

    case $USER_CHOICE in
        1)
            # Development: Use web server user
            FINAL_USER=$WEB_SERVER_USER
            ENVIRONMENT="development"
            log_info "Using web server user: $FINAL_USER"
            ;;
        2)
            # Production: Create new dedicated user
            ENVIRONMENT="production"
            echo ""
            echo "Creating a dedicated user for Laravel services provides:"
            echo "  ✓ Better security isolation"
            echo "  ✓ Clear ownership of processes"
            echo "  ✓ Sudo access for server management"
            echo ""

            read -p "Enter username for Laravel services (e.g., laraveladmin, deploy): " NEW_USER

            # Validate username
            if [ -z "$NEW_USER" ]; then
                log_error "Username cannot be empty"
                exit 1
            fi

            if ! [[ "$NEW_USER" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
                log_error "Invalid username. Must start with lowercase letter or underscore."
                exit 1
            fi

            # Check if user already exists
            if id "$NEW_USER" &>/dev/null; then
                log_error "User '$NEW_USER' already exists! Choose option 3 to use existing user."
                exit 1
            fi

            # Create user
            log_info "Creating user '$NEW_USER'..."
            useradd -m -s /bin/bash "$NEW_USER"

            if [ $? -eq 0 ]; then
                log_success "User created successfully"
            else
                log_error "Failed to create user"
                exit 1
            fi

            # Set password
            echo ""
            log_info "Set password for '$NEW_USER'"
            passwd "$NEW_USER"

            if [ $? -ne 0 ]; then
                log_error "Failed to set password"
                exit 1
            fi

            # Add to sudo group
            case $OS in
                ubuntu|debian)
                    usermod -aG sudo "$NEW_USER"
                    ;;
                centos|rhel|fedora|rocky|almalinux)
                    usermod -aG wheel "$NEW_USER"
                    ;;
                *)
                    if getent group sudo &>/dev/null; then
                        usermod -aG sudo "$NEW_USER"
                    elif getent group wheel &>/dev/null; then
                        usermod -aG wheel "$NEW_USER"
                    fi
                    ;;
            esac

            # Add to web server group
            usermod -aG "$WEB_SERVER_GROUP" "$NEW_USER"
            log_success "User '$NEW_USER' configured with sudo and web server access"

            FINAL_USER=$NEW_USER

            # SSH Key Generation for new user
            echo ""
            read -p "Generate SSH key for Git repository access? [Y/n]: " generate_ssh
            if [[ ! "$generate_ssh" =~ ^[Nn]$ ]]; then
                USER_HOME=$(eval echo ~$FINAL_USER)
                SSH_DIR="$USER_HOME/.ssh"
                SSH_KEY="$SSH_DIR/id_ed25519"

                # Create .ssh directory if it doesn't exist
                if [ ! -d "$SSH_DIR" ]; then
                    mkdir -p "$SSH_DIR"
                    chmod 700 "$SSH_DIR"
                    chown "$FINAL_USER:$FINAL_USER" "$SSH_DIR"
                fi

                if [ -f "$SSH_KEY" ]; then
                    log_warn "SSH key already exists at $SSH_KEY"
                else
                    log_info "Generating ED25519 SSH key..."
                    su - "$FINAL_USER" -c "ssh-keygen -t ed25519 -f $SSH_KEY -N '' -C '$FINAL_USER@$(hostname)'"

                    if [ $? -eq 0 ]; then
                        log_success "SSH key generated successfully"
                        echo ""
                        echo "========================================="
                        echo "  Public SSH Key"
                        echo "========================================="
                        cat "$SSH_KEY.pub"
                        echo "========================================="
                        echo ""
                        echo "Add this public key to your Git provider:"
                        echo "  • GitHub: Settings → SSH and GPG keys → New SSH key"
                        echo "  • GitLab: Preferences → SSH Keys → Add new key"
                        echo "  • Bitbucket: Personal settings → SSH keys → Add key"
                        echo ""
                        read -p "Press Enter after adding the key to your Git provider..."
                    else
                        log_error "Failed to generate SSH key"
                    fi
                fi
            fi
            ;;
        3)
            # Production: Use existing user
            ENVIRONMENT="production"
            echo ""
            echo "Available users:"
            # List users with home directories (excluding system users)
            awk -F: '$3 >= 1000 && $3 < 65534 {print "  - " $1}' /etc/passwd
            echo ""
            read -p "Enter username: " EXISTING_USER

            # Validate user exists
            if [ -z "$EXISTING_USER" ]; then
                log_error "Username cannot be empty"
                exit 1
            fi

            if ! id "$EXISTING_USER" &>/dev/null; then
                log_error "User '$EXISTING_USER' does not exist"
                exit 1
            fi

            # Ensure user is in web server group
            if ! groups "$EXISTING_USER" | grep -q "\b$WEB_SERVER_GROUP\b"; then
                log_info "Adding user to web server group..."
                usermod -aG "$WEB_SERVER_GROUP" "$EXISTING_USER"
                log_success "User added to $WEB_SERVER_GROUP group"
            fi

            FINAL_USER=$EXISTING_USER
            log_success "Using existing user: $FINAL_USER"

            # Check for existing SSH key
            echo ""
            USER_HOME=$(eval echo ~$FINAL_USER)
            SSH_DIR="$USER_HOME/.ssh"
            SSH_KEY_ED25519="$SSH_DIR/id_ed25519"
            SSH_KEY_RSA="$SSH_DIR/id_rsa"

            if [ -f "$SSH_KEY_ED25519" ] || [ -f "$SSH_KEY_RSA" ]; then
                log_info "SSH key found for user '$FINAL_USER'"
                read -p "Display public SSH key? [Y/n]: " display_key
                if [[ ! "$display_key" =~ ^[Nn]$ ]]; then
                    echo ""
                    echo "========================================="
                    echo "  Public SSH Key"
                    echo "========================================="
                    if [ -f "$SSH_KEY_ED25519.pub" ]; then
                        cat "$SSH_KEY_ED25519.pub"
                    elif [ -f "$SSH_KEY_RSA.pub" ]; then
                        cat "$SSH_KEY_RSA.pub"
                    fi
                    echo "========================================="
                    echo ""
                fi
            else
                log_warn "No SSH key found for user '$FINAL_USER'"
                read -p "Generate SSH key for Git repository access? [Y/n]: " generate_ssh
                if [[ ! "$generate_ssh" =~ ^[Nn]$ ]]; then
                    # Create .ssh directory if it doesn't exist
                    if [ ! -d "$SSH_DIR" ]; then
                        mkdir -p "$SSH_DIR"
                        chmod 700 "$SSH_DIR"
                        chown "$FINAL_USER:$FINAL_USER" "$SSH_DIR"
                    fi

                    log_info "Generating ED25519 SSH key..."
                    su - "$FINAL_USER" -c "ssh-keygen -t ed25519 -f $SSH_KEY_ED25519 -N '' -C '$FINAL_USER@$(hostname)'"

                    if [ $? -eq 0 ]; then
                        log_success "SSH key generated successfully"
                        echo ""
                        echo "========================================="
                        echo "  Public SSH Key"
                        echo "========================================="
                        cat "$SSH_KEY_ED25519.pub"
                        echo "========================================="
                        echo ""
                        echo "Add this public key to your Git provider:"
                        echo "  • GitHub: Settings → SSH and GPG keys → New SSH key"
                        echo "  • GitLab: Preferences → SSH Keys → Add new key"
                        echo "  • Bitbucket: Personal settings → SSH keys → Add key"
                        echo ""
                        read -p "Press Enter after adding the key to your Git provider..."
                    else
                        log_error "Failed to generate SSH key"
                    fi
                fi
            fi
            ;;
        *)
            log_error "Invalid choice"
            exit 1
            ;;
    esac
fi

echo ""

# Step 2: Deployment Source
log_step "Step 2/6: Deployment Source"
echo ""

echo "How would you like to deploy your Laravel application?"
echo ""
echo "1) Local directory  - Use existing Laravel installation on this server"
echo "2) Git repository   - Clone from a Git repository (GitHub/GitLab/Bitbucket)"
echo ""
read -p "Enter choice [1-2]: " DEPLOY_CHOICE

case $DEPLOY_CHOICE in
    1)
        # Local directory deployment
        DEPLOYMENT_METHOD="local"
        log_info "Selected: Local directory deployment"
        ;;
    2)
        # Git repository deployment
        DEPLOYMENT_METHOD="git"
        log_info "Selected: Git repository deployment"
        echo ""

        # Check if Git is installed
        if ! command -v git &>/dev/null; then
            log_error "Git is not installed!"
            echo ""
            echo "Install Git first:"
            case $OS in
                ubuntu|debian)
                    echo "  sudo apt update && sudo apt install -y git"
                    ;;
                centos|rhel|fedora|rocky|almalinux)
                    echo "  sudo yum install -y git"
                    ;;
            esac
            exit 1
        fi

        log_success "Git is installed (version: $(git --version | cut -d' ' -f3))"

        # Check if SSH key exists for the user
        USER_HOME=$(eval echo ~$FINAL_USER)
        SSH_DIR="$USER_HOME/.ssh"
        SSH_KEY_ED25519="$SSH_DIR/id_ed25519"
        SSH_KEY_RSA="$SSH_DIR/id_rsa"

        if [ ! -f "$SSH_KEY_ED25519" ] && [ ! -f "$SSH_KEY_RSA" ]; then
            log_error "No SSH key found for user '$FINAL_USER'"
            log_info "An SSH key is required for Git repository access"
            echo ""
            read -p "Generate SSH key now? [Y/n]: " generate_ssh_now
            if [[ ! "$generate_ssh_now" =~ ^[Nn]$ ]]; then
                # Create .ssh directory if it doesn't exist
                if [ ! -d "$SSH_DIR" ]; then
                    mkdir -p "$SSH_DIR"
                    chmod 700 "$SSH_DIR"
                    chown "$FINAL_USER:$FINAL_USER" "$SSH_DIR"
                fi

                log_info "Generating ED25519 SSH key..."
                su - "$FINAL_USER" -c "ssh-keygen -t ed25519 -f $SSH_KEY_ED25519 -N '' -C '$FINAL_USER@$(hostname)'"

                if [ $? -eq 0 ]; then
                    log_success "SSH key generated successfully"
                    echo ""
                    echo "========================================="
                    echo "  Public SSH Key"
                    echo "========================================="
                    cat "$SSH_KEY_ED25519.pub"
                    echo "========================================="
                    echo ""
                    echo "Add this public key to your Git provider:"
                    echo "  • GitHub: Settings → SSH and GPG keys → New SSH key"
                    echo "  • GitLab: Preferences → SSH Keys → Add new key"
                    echo "  • Bitbucket: Personal settings → SSH keys → Add key"
                    echo ""
                    read -p "Press Enter after adding the key to your Git provider..."
                else
                    log_error "Failed to generate SSH key"
                    exit 1
                fi
            else
                log_error "Cannot proceed without SSH key"
                exit 1
            fi
        else
            log_success "SSH key found for user '$FINAL_USER'"
            echo ""
            log_info "Reminder: Ensure your SSH public key is added to your Git provider"
            if [ -f "$SSH_KEY_ED25519.pub" ]; then
                echo "Public key location: $SSH_KEY_ED25519.pub"
            elif [ -f "$SSH_KEY_RSA.pub" ]; then
                echo "Public key location: $SSH_KEY_RSA.pub"
            fi
        fi

        echo ""
        read -p "Enter Git repository URL (e.g., git@github.com:user/repo.git): " GIT_REPO_URL

        # Validate Git URL
        if [ -z "$GIT_REPO_URL" ]; then
            log_error "Git repository URL cannot be empty"
            exit 1
        fi

        # Extract host from Git URL for known_hosts
        if [[ "$GIT_REPO_URL" =~ ^git@([^:]+): ]]; then
            GIT_HOST="${BASH_REMATCH[1]}"
        elif [[ "$GIT_REPO_URL" =~ ^https?://([^/]+) ]]; then
            GIT_HOST="${BASH_REMATCH[1]}"
        else
            log_warn "Could not extract hostname from Git URL"
            GIT_HOST=""
        fi

        echo ""
        read -p "Enter target directory for cloning (e.g., /var/www/myapp): " GIT_TARGET_DIR

        # Validate target directory
        if [ -z "$GIT_TARGET_DIR" ]; then
            log_error "Target directory cannot be empty"
            exit 1
        fi

        # Check if directory already exists
        if [ -d "$GIT_TARGET_DIR" ]; then
            log_error "Directory already exists: $GIT_TARGET_DIR"
            log_info "Please specify a non-existent directory or remove the existing one"
            exit 1
        fi

        # Create parent directory if it doesn't exist
        PARENT_DIR=$(dirname "$GIT_TARGET_DIR")
        if [ ! -d "$PARENT_DIR" ]; then
            log_info "Creating parent directory: $PARENT_DIR"
            mkdir -p "$PARENT_DIR"
        fi

        # Add Git host to known_hosts
        if [ -n "$GIT_HOST" ]; then
            log_info "Adding $GIT_HOST to known_hosts..."
            KNOWN_HOSTS="$SSH_DIR/known_hosts"

            # Check if host already in known_hosts
            if [ -f "$KNOWN_HOSTS" ]; then
                if grep -q "^$GIT_HOST " "$KNOWN_HOSTS" 2>/dev/null; then
                    log_info "Host already in known_hosts"
                else
                    ssh-keyscan -H "$GIT_HOST" >> "$KNOWN_HOSTS" 2>/dev/null
                    chown "$FINAL_USER:$FINAL_USER" "$KNOWN_HOSTS"
                    log_success "Added $GIT_HOST to known_hosts"
                fi
            else
                ssh-keyscan -H "$GIT_HOST" > "$KNOWN_HOSTS" 2>/dev/null
                chown "$FINAL_USER:$FINAL_USER" "$KNOWN_HOSTS"
                chmod 644 "$KNOWN_HOSTS"
                log_success "Created known_hosts and added $GIT_HOST"
            fi
        fi

        # Clone repository as the user
        echo ""
        log_info "Cloning repository..."
        log_info "Repository: $GIT_REPO_URL"
        log_info "Target: $GIT_TARGET_DIR"
        echo ""

        su - "$FINAL_USER" -c "git clone '$GIT_REPO_URL' '$GIT_TARGET_DIR'"

        if [ $? -ne 0 ]; then
            log_error "Failed to clone repository"
            log_info "Possible issues:"
            echo "  • SSH key not added to Git provider"
            echo "  • Repository URL is incorrect"
            echo "  • No access permissions to the repository"
            exit 1
        fi

        log_success "Repository cloned successfully!"

        # Optional: Checkout specific branch
        echo ""
        read -p "Checkout a specific branch? [y/N]: " checkout_branch
        if [[ "$checkout_branch" =~ ^[Yy]$ ]]; then
            read -p "Enter branch name: " BRANCH_NAME
            if [ -n "$BRANCH_NAME" ]; then
                log_info "Checking out branch: $BRANCH_NAME"
                su - "$FINAL_USER" -c "cd '$GIT_TARGET_DIR' && git checkout '$BRANCH_NAME'"
                if [ $? -eq 0 ]; then
                    log_success "Checked out branch: $BRANCH_NAME"
                else
                    log_warn "Failed to checkout branch: $BRANCH_NAME"
                fi
            fi
        fi

        # Set LARAVEL_PATH to the cloned directory
        LARAVEL_PATH="$GIT_TARGET_DIR"
        log_success "Laravel path set to: $LARAVEL_PATH"
        ;;
    *)
        log_error "Invalid choice"
        exit 1
        ;;
esac

echo ""

# Step 3: Laravel Application Path
log_step "Step 3/6: Laravel Application Path"
echo ""

if [ "$DEPLOYMENT_METHOD" = "local" ]; then
    # Local deployment - ask for path
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
else
    # Git deployment - path already set
    log_info "Using cloned repository at: $LARAVEL_PATH"

    # Verify it's a Laravel application
    if [ ! -f "$LARAVEL_PATH/artisan" ]; then
        log_warn "Warning: 'artisan' file not found in $LARAVEL_PATH"
        log_warn "This may not be a Laravel application"
    else
        log_success "Laravel application verified at: $LARAVEL_PATH"
    fi
fi

echo ""

# Step 4: Set File Permissions
log_step "Step 4/6: Setting File Permissions"
echo ""

log_info "Setting ownership to $FINAL_USER:$WEB_SERVER_GROUP..."
chown -R "$FINAL_USER:$WEB_SERVER_GROUP" "$LARAVEL_PATH"

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

# Step 5: Laravel Services Selection
log_step "Step 5/6: Laravel Services Configuration"
echo ""

# Check if Supervisor is available
if ! command -v supervisorctl &>/dev/null; then
    log_warn "Supervisor is not installed. Skipping service configuration."
    log_info "Install Supervisor and run this script again to configure services."
    SKIP_SERVICES=true
else
    SKIP_SERVICES=false

    echo "Which Laravel services do you want to configure?"
    echo "You can select multiple services (space-separated numbers)"
    echo ""
    echo "1) Horizon  - Queue worker management"
    echo "2) Reverb   - WebSocket server"
    echo "3) Pulse    - Application monitoring"
    echo "4) Schedule - Task scheduler"
    echo ""
    read -p "Enter choices (e.g., '1 2 4' or 'all' or 'none'): " SERVICES_CHOICE

    # Parse service selection
    SERVICES_TO_SETUP=()

    if [[ "$SERVICES_CHOICE" == "all" ]]; then
        SERVICES_TO_SETUP=("horizon" "reverb" "pulse" "schedule")
    elif [[ "$SERVICES_CHOICE" == "none" ]]; then
        SERVICES_TO_SETUP=()
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
fi

if [ "$SKIP_SERVICES" = false ] && [ ${#SERVICES_TO_SETUP[@]} -gt 0 ]; then
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

        # Update user in the config
        sed -i "s/^user=.*/user=$FINAL_USER/" "$DEST_FILE"

        # Update paths in the config
        sed -i "s|command=php /var/www/html/artisan|command=php $LARAVEL_PATH/artisan|g" "$DEST_FILE"
        sed -i "s|stdout_logfile=/var/www/html/storage/logs|stdout_logfile=$LARAVEL_PATH/storage/logs|g" "$DEST_FILE"

        log_success "Configured: laravel-$service.conf"
    done
elif [ "$SKIP_SERVICES" = false ]; then
    log_info "No services selected"
fi

echo ""

# Step 6: Start Services
if [ "$SKIP_SERVICES" = false ] && [ ${#SERVICES_TO_SETUP[@]} -gt 0 ]; then
    log_step "Step 6/6: Starting Services"
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
else
    log_step "Step 6/6: Services"
    echo ""
    log_info "Skipping service configuration"
fi

echo ""

# Save app configuration for future runs
cat > "$APP_CONFIG_FILE" << EOF
# Laravel App Configuration
# Generated on $(date)

SUPERVISOR_USER=$FINAL_USER
ENVIRONMENT=${ENVIRONMENT:-development}
LAST_APP_PATH=$LARAVEL_PATH
DEPLOYMENT_METHOD=$DEPLOYMENT_METHOD
EOF

chmod 600 "$APP_CONFIG_FILE"

# Display summary
echo "========================================="
echo "  Setup Complete!"
echo "========================================="
echo ""
echo "Deployment Method: $DEPLOYMENT_METHOD"
if [ "$DEPLOYMENT_METHOD" = "git" ]; then
    echo "Repository: $GIT_REPO_URL"
fi
echo "Application: $LARAVEL_PATH"
echo "User: $FINAL_USER"
echo "Owner: $FINAL_USER:$WEB_SERVER_GROUP"
echo ""

if [ "$SKIP_SERVICES" = false ] && [ ${#SERVICES_TO_SETUP[@]} -gt 0 ]; then
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

if [ "$DEPLOYMENT_METHOD" = "git" ]; then
    echo "Git operations (as $FINAL_USER):"
    echo "  cd $LARAVEL_PATH"
    echo "  git pull origin main"
    echo "  git fetch --all"
    echo "  git checkout <branch-name>"
    echo ""
fi

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

if [ "$FINAL_USER" != "$WEB_SERVER_USER" ]; then
    echo "Switch to Laravel user:"
    echo "  su - $FINAL_USER"
    echo ""
fi

log_success "Laravel application configured successfully!"
echo ""
log_info "You can run this script again to deploy additional Laravel apps"
