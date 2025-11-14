#!/bin/bash

#############################
# PHP 8.4 Setup Script
# Supports: Ubuntu and Alpine
#############################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        log_error "Cannot detect OS. /etc/os-release not found."
        exit 1
    fi

    log_info "Detected OS: $OS $OS_VERSION"
}

# Ubuntu Installation
install_ubuntu() {
    log_info "Starting PHP 8.4 installation on Ubuntu..."

    # Prompt for web server
    echo ""
    echo "Select web server:"
    echo "1) Apache"
    echo "2) Nginx"
    read -p "Enter choice [1-2]: " webserver_choice

    # Prompt for database server installation
    echo ""
    echo "Install database server? (Note: Database client extensions will be installed regardless)"
    echo "1) MySQL Server"
    echo "2) PostgreSQL Server"
    echo "3) None"
    read -p "Enter choice [1-3]: " database_choice

    # Prompt for Redis server installation
    echo ""
    echo "Install Redis Server? (Note: Redis extension will be installed regardless)"
    echo "1) Yes"
    echo "2) No"
    read -p "Enter choice [1-2]: " redis_choice

    # Prompt for additional PHP extensions
    echo ""
    echo "========================================="
    echo "Additional PHP Extensions (Optional)"
    echo "========================================="
    echo "Enter the numbers of extensions you want to install (space-separated, e.g., '1 3 5')"
    echo "Press Enter to skip all optional extensions"
    echo ""
    echo "1) Imagick      - Advanced image processing with ImageMagick"
    echo "2) Xdebug       - Debugging and profiling tool"
    echo "3) Memcached    - Memcached caching support"
    echo "4) APCu         - APCu user cache"
    echo "5) MongoDB      - MongoDB database support"
    echo "6) LDAP         - LDAP directory access"
    echo "7) IMAP         - Email IMAP support"
    echo "8) SSH2         - SSH2 protocol support"
    echo "9) Swoole       - High-performance async framework"
    echo "10) AMQP        - RabbitMQ/AMQP messaging support"
    echo ""
    read -p "Enter your choices: " additional_extensions

    log_info "Updating package lists..."
    apt-get update

    # Install prerequisites
    log_info "Installing prerequisites..."
    apt-get install -y software-properties-common ca-certificates lsb-release apt-transport-https curl

    # Add Ondrej PHP PPA
    log_info "Adding Ondrej PHP PPA..."
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
    apt-get update

    # Install PHP 8.4 and common extensions
    log_info "Installing PHP 8.4 and extensions..."

    PHP_PACKAGES=(
        php8.4
        php8.4-cli
        php8.4-common
        php8.4-fpm
        php8.4-curl
        php8.4-mbstring
        php8.4-xml
        php8.4-zip
        php8.4-bcmath
        php8.4-intl
        php8.4-gd
        php8.4-soap
        php8.4-opcache
        php8.4-readline
        php8.4-tokenizer
        php8.4-fileinfo
        php8.4-mysql
        php8.4-pgsql
        php8.4-redis
    )

    log_info "Installing database client extensions (MySQL & PostgreSQL)..."
    log_info "Installing Redis extension..."

    # Process additional extensions
    if [ -n "$additional_extensions" ]; then
        log_info "Processing additional extensions..."
        for ext_num in $additional_extensions; do
            case $ext_num in
                1)
                    log_info "Adding Imagick extension..."
                    PHP_PACKAGES+=(php8.4-imagick)
                    ;;
                2)
                    log_info "Adding Xdebug extension..."
                    PHP_PACKAGES+=(php8.4-xdebug)
                    ;;
                3)
                    log_info "Adding Memcached extension..."
                    PHP_PACKAGES+=(php8.4-memcached)
                    ;;
                4)
                    log_info "Adding APCu extension..."
                    PHP_PACKAGES+=(php8.4-apcu)
                    ;;
                5)
                    log_info "Adding MongoDB extension..."
                    PHP_PACKAGES+=(php8.4-mongodb)
                    ;;
                6)
                    log_info "Adding LDAP extension..."
                    PHP_PACKAGES+=(php8.4-ldap)
                    ;;
                7)
                    log_info "Adding IMAP extension..."
                    PHP_PACKAGES+=(php8.4-imap)
                    ;;
                8)
                    log_info "Adding SSH2 extension..."
                    PHP_PACKAGES+=(php8.4-ssh2)
                    ;;
                9)
                    log_info "Adding Swoole extension..."
                    # Swoole might need PECL installation
                    PHP_PACKAGES+=(php8.4-dev)
                    INSTALL_SWOOLE=true
                    ;;
                10)
                    log_info "Adding AMQP extension..."
                    PHP_PACKAGES+=(php8.4-amqp)
                    ;;
                *)
                    log_warn "Unknown extension number: $ext_num (skipping)"
                    ;;
            esac
        done
    fi

    apt-get install -y "${PHP_PACKAGES[@]}"

    # Install Swoole via PECL if selected
    if [ "$INSTALL_SWOOLE" = true ]; then
        log_info "Installing Swoole via PECL..."
        apt-get install -y build-essential
        pecl install swoole
        echo "extension=swoole.so" > /etc/php/8.4/mods-available/swoole.ini
        phpenmod swoole
    fi

    # Install and configure web server
    case $webserver_choice in
        1)
            log_info "Installing Apache..."
            apt-get install -y apache2 libapache2-mod-php8.4

            # Enable necessary Apache modules
            a2enmod rewrite
            a2enmod php8.4

            # Configure Apache
            log_info "Configuring Apache..."
            systemctl enable apache2
            systemctl restart apache2
            ;;
        2)
            log_info "Installing Nginx..."
            apt-get install -y nginx

            # Configure Nginx
            log_info "Configuring Nginx..."
            systemctl enable nginx
            systemctl enable php8.4-fpm
            systemctl restart php8.4-fpm
            systemctl restart nginx
            ;;
    esac

    # Install database server
    case $database_choice in
        1)
            log_info "Installing MySQL Server..."
            apt-get install -y mysql-server
            systemctl enable mysql
            systemctl start mysql
            log_warn "Please run 'mysql_secure_installation' to secure your MySQL installation"
            ;;
        2)
            log_info "Installing PostgreSQL Server..."
            apt-get install -y postgresql postgresql-contrib
            systemctl enable postgresql
            systemctl start postgresql
            log_warn "PostgreSQL installed. Default user is 'postgres'"
            ;;
        3)
            log_info "Skipping database server installation (client extensions already installed)..."
            ;;
    esac

    # Install Redis server
    if [ "$redis_choice" == "1" ]; then
        log_info "Installing Redis Server..."
        apt-get install -y redis-server
        systemctl enable redis-server
        systemctl start redis-server
    else
        log_info "Skipping Redis server installation (Redis extension already installed)..."
    fi

    # Install Composer
    install_composer

    log_info "Ubuntu PHP 8.4 installation completed!"
    display_versions_ubuntu
}

# Alpine Installation
install_alpine() {
    log_info "Starting PHP 8.4 installation on Alpine..."

    log_info "Updating package index..."
    apk update

    log_info "Installing PHP 8.4 and extensions..."

    apk add --no-cache \
        php84 \
        php84-fpm \
        php84-cli \
        php84-curl \
        php84-mbstring \
        php84-xml \
        php84-zip \
        php84-bcmath \
        php84-intl \
        php84-gd \
        php84-soap \
        php84-opcache \
        php84-pdo \
        php84-pdo_mysql \
        php84-pdo_pgsql \
        php84-mysqli \
        php84-pgsql \
        php84-redis \
        php84-tokenizer \
        php84-fileinfo \
        php84-session \
        php84-ctype \
        php84-json \
        php84-openssl \
        php84-dom \
        php84-xmlreader \
        php84-xmlwriter \
        php84-simplexml \
        php84-phar

    # Create symlinks for default php command
    log_info "Creating symlinks..."
    ln -sf /usr/bin/php84 /usr/bin/php
    ln -sf /usr/sbin/php-fpm84 /usr/sbin/php-fpm

    # Configure PHP-FPM
    log_info "Configuring PHP-FPM..."
    rc-update add php-fpm84 default
    rc-service php-fpm84 start

    # Install Composer
    install_composer

    log_info "Alpine PHP 8.4 installation completed!"
    display_versions_alpine
}

# Install Composer
install_composer() {
    log_info "Installing Composer..."

    EXPECTED_CHECKSUM="$(curl -sS https://composer.github.io/installer.sig)"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
        log_error "Invalid Composer installer checksum"
        rm composer-setup.php
        return 1
    fi

    php composer-setup.php --quiet --install-dir=/usr/local/bin --filename=composer
    rm composer-setup.php

    log_info "Composer installed successfully"
}

# Display versions for Ubuntu
display_versions_ubuntu() {
    echo ""
    echo "========================================="
    log_info "Installation Summary"
    echo "========================================="
    echo ""

    php -v | head -n 1
    composer --version 2>/dev/null || echo "Composer: Not installed"

    case $webserver_choice in
        1)
            apache2 -v | head -n 1
            ;;
        2)
            nginx -v 2>&1
            ;;
    esac

    case $database_choice in
        1)
            mysql --version 2>/dev/null || echo "MySQL: Not installed"
            ;;
        2)
            psql --version 2>/dev/null || echo "PostgreSQL: Not installed"
            ;;
    esac

    if [ "$redis_choice" == "1" ]; then
        redis-server --version 2>/dev/null || echo "Redis: Not installed"
    fi

    echo ""
    echo "========================================="
    log_info "PHP 8.4 Extensions"
    echo "========================================="
    php -m

    echo ""
    log_info "Setup complete!"
}

# Display versions for Alpine
display_versions_alpine() {
    echo ""
    echo "========================================="
    log_info "Installation Summary"
    echo "========================================="
    echo ""

    php -v | head -n 1
    composer --version 2>/dev/null || echo "Composer: Not installed"

    echo ""
    echo "========================================="
    log_info "PHP 8.4 Extensions"
    echo "========================================="
    php -m

    echo ""
    log_info "Setup complete!"
    log_info "To start PHP-FPM: rc-service php-fpm84 start"
}

# Main execution
main() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        exit 1
    fi

    echo "========================================="
    echo "     PHP 8.4 Setup Script"
    echo "========================================="
    echo ""

    detect_os

    case $OS in
        ubuntu|debian)
            install_ubuntu
            ;;
        alpine)
            install_alpine
            ;;
        *)
            log_error "Unsupported OS: $OS"
            log_error "This script supports Ubuntu and Alpine only"
            exit 1
            ;;
    esac
}

main
