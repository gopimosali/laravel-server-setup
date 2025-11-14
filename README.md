# PHP 8.4 Setup Script

Automated installation script for PHP 8.4 with support for Ubuntu and Alpine Linux.

## Repository Contents

- **`setup-php84.sh`** - Main installation script
- **`php.ini.sample`** - Production-ready PHP configuration
- **`apache-virtualhost.conf.sample`** - Apache virtual host template
- **`nginx-virtualhost.conf.sample`** - Nginx server block template
- **`README.md`** - This documentation

## Features

- **OS Support**: Ubuntu and Alpine Linux
- **PHP 8.4**: Latest PHP version with common extensions
- **All Database Clients**: MySQL and PostgreSQL extensions always installed
- **Redis Extension**: Always installed for caching support
- **Interactive Setup** (Ubuntu only):
  - Web server selection (Apache or Nginx)
  - Database server installation (MySQL Server, PostgreSQL Server, or None)
  - Redis server installation option
  - Node.js installation (LTS, Current, or None)
  - Optional extensions (Imagick, Xdebug, Memcached, APCu, MongoDB, LDAP, IMAP, SSH2, Swoole, AMQP)
- **Automatic Composer Installation**
- **Complete Laravel/PHP Application Stack**
- **Sample Configuration Files**: Production-ready configs for PHP, Apache, and Nginx

## Configuration Files

This repository includes sample configuration files to help you set up your server:

- **`php.ini.sample`** - Production-ready PHP 8.4 configuration with security best practices
- **`apache-virtualhost.conf.sample`** - Apache virtual host configuration for Laravel/PHP apps
- **`nginx-virtualhost.conf.sample`** - Nginx server block configuration for Laravel/PHP apps

See the [Configuration](#configuration) section for detailed instructions on using these files.

## Requirements

- Root/sudo access
- Supported OS: Ubuntu 20.04+, Debian 11+, or Alpine Linux
- Internet connection

## Usage

### Quick Start

```bash
# Make script executable
chmod +x setup-php84.sh

# Run the script with root privileges
sudo ./setup-php84.sh
```

### Ubuntu Interactive Setup

When running on Ubuntu, you'll be prompted to make the following selections:

**Note**: Database client extensions (MySQL & PostgreSQL) and Redis extension are **always installed** regardless of your choices. The prompts below are only for installing the actual **servers**.

#### 1. Web Server
- **Apache** - Traditional web server with mod_php
- **Nginx** - Modern web server with PHP-FPM

#### 2. Database Server (Client extensions always installed)
- **MySQL Server** - Install MySQL database server
- **PostgreSQL Server** - Install PostgreSQL database server
- **None** - Skip server installation (you can connect to remote databases using the installed client extensions)

#### 3. Redis Server (Redis extension always installed)
- **Yes** - Install Redis server locally
- **No** - Skip server installation (you can connect to remote Redis using the installed extension)

#### 4. Node.js Installation (Optional)
- **Node.js LTS** - Long Term Support version (Recommended for production)
- **Node.js Current** - Latest features and updates
- **None** - Skip Node.js installation

Node.js and npm are useful for:
- Frontend asset compilation (Vite, Laravel Mix, Webpack)
- Running build tools and task runners
- Package management with npm/yarn

#### 5. Additional PHP Extensions (Optional)
You can select additional extensions based on your needs (multi-select):

1. **Imagick** - Advanced image processing with ImageMagick
2. **Xdebug** - Debugging and profiling tool (recommended for development)
3. **Memcached** - Memcached caching support
4. **APCu** - APCu user cache for better performance
5. **MongoDB** - MongoDB NoSQL database support
6. **LDAP** - LDAP directory access
7. **IMAP** - Email IMAP support
8. **SSH2** - SSH2 protocol support
9. **Swoole** - High-performance async framework (installed via PECL)
10. **AMQP** - RabbitMQ/AMQP messaging support

Simply enter the numbers space-separated (e.g., "1 2 4") or press Enter to skip.

### Alpine Installation

Alpine installation is fully automated and includes:
- PHP 8.4 with all common extensions
- PHP-FPM
- Composer
- Support for MySQL, PostgreSQL, and Redis (extensions installed)

## PHP Extensions Included

The script installs the following PHP 8.4 extensions:

### Core Extensions
- `cli` - Command line interface
- `fpm` - FastCGI Process Manager
- `common` - Common files
- `curl` - cURL support
- `mbstring` - Multibyte string support
- `xml` - XML support
- `zip` - ZIP archive support

### Laravel/Application Extensions
- `bcmath` - Arbitrary precision mathematics
- `intl` - Internationalization
- `gd` - Image processing
- `soap` - SOAP protocol support
- `opcache` - Opcode cache
- `readline` - Readline support
- `tokenizer` - Tokenizer support
- `fileinfo` - File information support

### Database Extensions (Always Installed)
- `mysql`/`mysqli`/`pdo_mysql` - MySQL client support
- `pgsql`/`pdo_pgsql` - PostgreSQL client support

### Cache Extensions (Always Installed)
- `redis` - Redis support

### Optional Extensions (Ubuntu - Select During Installation)
- `imagick` - Advanced image manipulation with ImageMagick
- `xdebug` - Debugging and profiling (WARNING: disable in production)
- `memcached` - Memcached cache support
- `apcu` - APCu opcode cache
- `mongodb` - MongoDB database driver
- `ldap` - LDAP directory services
- `imap` - IMAP email protocol
- `ssh2` - SSH2 protocol support
- `swoole` - Async, coroutine-based framework
- `amqp` - RabbitMQ/AMQP messaging

## Post-Installation

### Ubuntu

#### Apache Configuration
```bash
# Default web root: /var/www/html
# Apache config: /etc/apache2/
# Restart Apache:
sudo systemctl restart apache2
```

#### Nginx Configuration
```bash
# Default web root: /var/www/html
# Nginx config: /etc/nginx/
# Restart Nginx:
sudo systemctl restart nginx
sudo systemctl restart php8.4-fpm
```

#### MySQL Setup
```bash
# Secure your MySQL installation:
sudo mysql_secure_installation
```

#### PostgreSQL Setup
```bash
# Switch to postgres user:
sudo -u postgres psql
```

### Alpine

```bash
# Start PHP-FPM
rc-service php-fpm84 start

# Enable PHP-FPM on boot
rc-update add php-fpm84 default
```

## Verification

After installation, verify your setup:

```bash
# Check PHP version
php -v

# List installed PHP extensions
php -m

# Check Composer
composer --version

# Check Node.js and npm (if installed)
node --version
npm --version

# Check web server (Ubuntu)
# For Apache:
sudo systemctl status apache2

# For Nginx:
sudo systemctl status nginx
sudo systemctl status php8.4-fpm
```

## Configuration

### PHP Configuration

The `php.ini.sample` file contains production-ready PHP 8.4 settings with security best practices.

**To use the PHP configuration:**

```bash
# Backup original php.ini
sudo cp /etc/php/8.4/fpm/php.ini /etc/php/8.4/fpm/php.ini.backup

# Copy sample configuration
sudo cp php.ini.sample /etc/php/8.4/fpm/php.ini

# Edit settings as needed
sudo nano /etc/php/8.4/fpm/php.ini

# Restart PHP-FPM
sudo systemctl restart php8.4-fpm
```

**Key settings in php.ini.sample:**
- **Security**: `expose_php = Off`, `disable_functions` for dangerous functions
- **Performance**: OPcache enabled with optimized settings
- **Error Handling**: Production-safe error reporting
- **Memory**: 128M default (adjust for your needs)
- **Upload Limits**: 10M files, 12M POST data
- **Sessions**: Secure cookie settings

### Apache Virtual Host Configuration

The `apache-virtualhost.conf.sample` file provides a complete Apache configuration for Laravel/PHP applications.

**To use the Apache configuration:**

```bash
# Copy sample to sites-available
sudo cp apache-virtualhost.conf.sample /etc/apache2/sites-available/your-app.conf

# Edit configuration
sudo nano /etc/apache2/sites-available/your-app.conf

# Update these values:
# - ServerName (your domain)
# - ServerAlias (www subdomain)
# - ServerAdmin (your email)
# - DocumentRoot (path to your app)

# Enable the site
sudo a2ensite your-app.conf

# Test configuration
sudo apache2ctl configtest

# Reload Apache
sudo systemctl reload apache2
```

**Features included:**
- Laravel-ready configuration with URL rewriting
- Security headers and file access restrictions
- SSL/TLS configuration (commented, ready to enable)
- Logging configuration
- Performance optimization tips

### Nginx Server Block Configuration

The `nginx-virtualhost.conf.sample` file provides a complete Nginx configuration for Laravel/PHP applications.

**To use the Nginx configuration:**

```bash
# Copy sample to sites-available
sudo cp nginx-virtualhost.conf.sample /etc/nginx/sites-available/your-app

# Edit configuration
sudo nano /etc/nginx/sites-available/your-app

# Update these values:
# - server_name (your domain)
# - root (path to your app)
# - Log file paths

# Create symbolic link
sudo ln -s /etc/nginx/sites-available/your-app /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

**Features included:**
- PHP-FPM integration with optimized settings
- Security headers (X-Frame-Options, HSTS, etc.)
- Static file caching and Gzip compression
- SSL/TLS configuration (commented, ready to enable)
- Laravel-specific routing and file protection
- Performance optimization settings

### SSL/TLS Certificate (Let's Encrypt)

Both Apache and Nginx configurations include commented SSL sections. To enable HTTPS:

```bash
# Install Certbot
# For Apache:
sudo apt install certbot python3-certbot-apache

# For Nginx:
sudo apt install certbot python3-certbot-nginx

# Get certificate and auto-configure
# For Apache:
sudo certbot --apache -d example.com -d www.example.com

# For Nginx:
sudo certbot --nginx -d example.com -d www.example.com

# Auto-renewal is enabled by default
# Test renewal:
sudo certbot renew --dry-run
```

## Laravel Deployment Example

```bash
# Install Laravel
composer create-project laravel/laravel my-app

# Configure permissions (Ubuntu)
cd my-app
sudo chown -R www-data:www-data storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache

# Configure your .env file
cp .env.example .env
php artisan key:generate

# Run migrations (if database installed)
php artisan migrate

# Install frontend dependencies (if Node.js installed)
npm install

# Build frontend assets
npm run build       # For production
npm run dev         # For development
```

**Note**: For detailed web server configuration, see the [Configuration](#configuration) section above which includes complete sample files for both Apache and Nginx.

## Managing Optional Extensions

### Disabling Xdebug in Production

Xdebug significantly impacts performance and should be disabled in production:

```bash
# Disable Xdebug (Ubuntu)
sudo phpdismod xdebug
sudo systemctl restart php8.4-fpm  # for Nginx
sudo systemctl restart apache2     # for Apache

# Enable Xdebug for development
sudo phpenmod xdebug
sudo systemctl restart php8.4-fpm  # for Nginx
sudo systemctl restart apache2     # for Apache
```

### Enabling/Disabling Extensions

```bash
# List all available modules
php -m

# Disable an extension
sudo phpdismod <extension-name>

# Enable an extension
sudo phpenmod <extension-name>

# Restart web server/PHP-FPM after changes
sudo systemctl restart php8.4-fpm
```

## Troubleshooting

### PHP-FPM Socket Issues (Ubuntu/Nginx)
```bash
# Check if PHP-FPM is running
sudo systemctl status php8.4-fpm

# Restart PHP-FPM
sudo systemctl restart php8.4-fpm
```

### Permission Issues
```bash
# Fix web directory permissions
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
```

### Extension Not Found
```bash
# Search for available PHP 8.4 packages (Ubuntu)
apt search php8.4-

# Install additional extension
sudo apt install php8.4-<extension-name>
```

## Security Recommendations

1. **Firewall**: Configure firewall to allow only necessary ports
2. **MySQL**: Run `mysql_secure_installation` after installation
3. **PostgreSQL**: Configure `pg_hba.conf` for secure access
4. **PHP**: Review `php.ini` settings for production use
5. **Xdebug**: ALWAYS disable Xdebug in production environments (significant performance impact and security risk)
6. **Updates**: Regularly update packages for security patches

## Uninstallation

### Ubuntu
```bash
# Remove PHP 8.4
sudo apt remove --purge php8.4*

# Remove web server
sudo apt remove --purge apache2  # or nginx

# Remove database
sudo apt remove --purge mysql-server  # or postgresql

# Remove Redis
sudo apt remove --purge redis-server
```

### Alpine
```bash
# Remove PHP 8.4
apk del php84*
```

## License

This script is provided as-is for setting up PHP development environments.

## Support

For issues or questions, please open an issue in the repository.
