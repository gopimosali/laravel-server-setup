# PHP 8.4 Setup Script

Automated installation script for PHP 8.4 with support for Ubuntu and Alpine Linux.

## Repository Contents

- **`setup-php84.sh`** - Main installation script
- **`php.ini.sample`** - Production-ready PHP configuration
- **`apache-virtualhost.conf.sample`** - Apache virtual host template
- **`nginx-virtualhost.conf.sample`** - Nginx server block template
- **`supervisor-reverb.conf.sample`** - Supervisor config for Laravel Reverb WebSocket server
- **`supervisor-horizon.conf.sample`** - Supervisor config for Laravel Horizon queue worker
- **`supervisor-pulse.conf.sample`** - Supervisor config for Laravel Pulse monitoring
- **`supervisor-schedule.conf.sample`** - Supervisor config for Laravel task scheduler
- **`setup-laravel-user.sh`** - Create dedicated user for Laravel services (RECOMMENDED)
- **`update-supervisor-user.sh`** - Update user in Supervisor configs
- **`fix-laravel-permissions.sh`** - Set correct Laravel file ownership and permissions
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
- **Sample Configuration Files**: Production-ready configs for PHP, Apache, Nginx, and Supervisor

## Configuration Files

This repository includes sample configuration files to help you set up your server:

### Web Server & PHP
- **`php.ini.sample`** - Production-ready PHP 8.4 configuration with security best practices
- **`apache-virtualhost.conf.sample`** - Apache virtual host configuration for Laravel/PHP apps
- **`nginx-virtualhost.conf.sample`** - Nginx server block configuration for Laravel/PHP apps

### Laravel Services (Supervisor)
- **`supervisor-reverb.conf.sample`** - Supervisor config for Laravel Reverb (WebSocket server)
- **`supervisor-horizon.conf.sample`** - Supervisor config for Laravel Horizon (queue management)
- **`supervisor-pulse.conf.sample`** - Supervisor config for Laravel Pulse (application monitoring)
- **`supervisor-schedule.conf.sample`** - Supervisor config for Laravel Scheduler (task scheduling)

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

### Supervisor Configuration for Laravel Services

The repository includes Supervisor configuration files for managing Laravel's long-running processes. Supervisor ensures these services stay running and automatically restarts them if they crash.

#### Available Configurations

1. **Laravel Reverb** (`supervisor-reverb.conf.sample`) - WebSocket server
2. **Laravel Horizon** (`supervisor-horizon.conf.sample`) - Queue worker management
3. **Laravel Pulse** (`supervisor-pulse.conf.sample`) - Application monitoring
4. **Laravel Scheduler** (`supervisor-schedule.conf.sample`) - Task scheduling

#### Installing Supervisor

```bash
# Install Supervisor (Ubuntu)
sudo apt update
sudo apt install supervisor

# Enable and start Supervisor
sudo systemctl enable supervisor
sudo systemctl start supervisor
```

#### Automated Setup (Recommended for Production)

**Best Practice:** Create a dedicated user for running Laravel services instead of using the web server user directly. This provides better security and flexibility.

**Option A: Dedicated Laravel User (RECOMMENDED for Production)**

```bash
# Step 1: Create a dedicated Laravel user
chmod +x setup-laravel-user.sh
sudo ./setup-laravel-user.sh

# This script will:
# - Prompt for a username (e.g., laraveladmin, deploy)
# - Create the user with a password
# - Add user to sudo group for server management
# - Add user to web server group for file access
# - Update all supervisor config files to use this user
# - Optionally set up Laravel file permissions
```

After running this script, supervisor processes will run as your dedicated user, providing:
- **Better Security**: Separation from web server user
- **Easier Management**: Single user for all Laravel services
- **Sudo Access**: Can manage server without switching users
- **Clean Permissions**: Files owned by dedicated user, accessible by web server

**Option B: Web Server User (Simpler, for Development)**

If you prefer to use the web server user (www-data, nginx, apache):

```bash
# Step 1: Update Supervisor configs
chmod +x update-supervisor-user.sh
./update-supervisor-user.sh

# Step 2: Fix Laravel permissions
chmod +x fix-laravel-permissions.sh
sudo ./fix-laravel-permissions.sh
```

#### Manual Setup Process

If you prefer to configure manually:

**Step 1: Update User in Config Files**

Edit each supervisor config file and update the `user=` line to match your web server user:
- Ubuntu/Debian with Apache or Nginx: `www-data`
- CentOS/RHEL with Apache: `apache`
- CentOS/RHEL with Nginx: `nginx`

**Step 2: Copy and Configure**

```bash
# 1. Copy the sample file(s) you need to /etc/supervisor/conf.d/
sudo cp supervisor-horizon.conf.sample /etc/supervisor/conf.d/laravel-horizon.conf

# 2. Edit the configuration file
sudo nano /etc/supervisor/conf.d/laravel-horizon.conf

# Update these values:
# - command: Path to your Laravel installation
# - user: Your web server user (www-data, nginx, etc.)
# - stdout_logfile: Path to your log directory

# 3. Reload Supervisor to recognize the new configuration
sudo supervisorctl reread
sudo supervisorctl update

# 4. Start the service
sudo supervisorctl start laravel-horizon:*

# 5. Check status
sudo supervisorctl status
```

#### Service-Specific Setup

**Laravel Horizon (Queue Management):**

```bash
# Install Horizon
composer require laravel/horizon
php artisan horizon:install
php artisan migrate

# Configure Supervisor
sudo cp supervisor-horizon.conf.sample /etc/supervisor/conf.d/laravel-horizon.conf
sudo nano /etc/supervisor/conf.d/laravel-horizon.conf
sudo supervisorctl reread && sudo supervisorctl update
sudo supervisorctl start laravel-horizon:*

# Access dashboard: https://your-domain.com/horizon
```

**Laravel Reverb (WebSocket Server):**

```bash
# Install Reverb
composer require laravel/reverb
php artisan reverb:install

# Configure .env
# REVERB_APP_ID, REVERB_APP_KEY, REVERB_APP_SECRET, etc.

# Configure Supervisor
sudo cp supervisor-reverb.conf.sample /etc/supervisor/conf.d/laravel-reverb.conf
sudo nano /etc/supervisor/conf.d/laravel-reverb.conf
sudo supervisorctl reread && sudo supervisorctl update
sudo supervisorctl start laravel-reverb:*

# Allow firewall access to WebSocket port
sudo ufw allow 8080/tcp
```

**Laravel Pulse (Application Monitoring):**

```bash
# Install Pulse
composer require laravel/pulse
php artisan vendor:publish --provider="Laravel\Pulse\PulseServiceProvider"
php artisan migrate

# Configure Supervisor
sudo cp supervisor-pulse.conf.sample /etc/supervisor/conf.d/laravel-pulse.conf
sudo nano /etc/supervisor/conf.d/laravel-pulse.conf
sudo supervisorctl reread && sudo supervisorctl update
sudo supervisorctl start laravel-pulse:*

# Access dashboard: https://your-domain.com/pulse
```

**Laravel Scheduler:**

```bash
# Option 1: Using Supervisor (this config)
sudo cp supervisor-schedule.conf.sample /etc/supervisor/conf.d/laravel-schedule.conf
sudo nano /etc/supervisor/conf.d/laravel-schedule.conf
sudo supervisorctl reread && sudo supervisorctl update
sudo supervisorctl start laravel-schedule:*

# Option 2: Using Cron (traditional method - choose ONE)
sudo crontab -e -u www-data
# Add: * * * * * cd /var/www/html && php artisan schedule:run >> /dev/null 2>&1

# Test scheduled tasks
php artisan schedule:list
```

#### Managing Supervisor Services

```bash
# Check status of all services
sudo supervisorctl status

# Start a service
sudo supervisorctl start laravel-horizon:*

# Stop a service
sudo supervisorctl stop laravel-horizon:*

# Restart a service
sudo supervisorctl restart laravel-horizon:*

# View logs
sudo supervisorctl tail -f laravel-horizon:laravel-horizon_00 stdout

# Restart all services
sudo supervisorctl restart all

# Reload Supervisor configuration
sudo supervisorctl reread
sudo supervisorctl update
```

#### Important Notes

1. **File Paths**: Always update the paths in the config files to match your Laravel installation
2. **User Permissions**: Ensure the user specified in the config has proper permissions to run the commands
3. **Log Directories**: Create log directories if they don't exist and ensure they're writable
4. **After Deployment**: Restart services after deploying new code:
   ```bash
   # For Horizon (graceful)
   php artisan horizon:terminate

   # For others
   sudo supervisorctl restart laravel-reverb:*
   sudo supervisorctl restart laravel-pulse:*
   sudo supervisorctl restart laravel-schedule:*
   ```
5. **Monitoring**: Regularly check logs and service status to ensure everything is running correctly

### User Configuration Best Practices

#### Production Setup (Recommended)

For production environments, use a **dedicated user** for Laravel services:

```bash
# Create dedicated Laravel user
sudo ./setup-laravel-user.sh

# Example user: laraveladmin, deploy, laravel, etc.
```

**Benefits:**
- **Security Isolation**: Laravel processes run separately from web server
- **Permission Management**: Clean separation of concerns
- **Easier Debugging**: Clear ownership of processes and files
- **Sudo Access**: User can manage server and Laravel without switching
- **Group Membership**: User belongs to web server group for file sharing

**File Ownership Pattern:**
```
Owner: laraveladmin (your dedicated user)
Group: www-data (web server group)
Directories: 755
Files: 644
storage/: 775 (owner + group can write)
bootstrap/cache/: 775 (owner + group can write)
```

This allows:
- Your dedicated user to manage Laravel files
- Web server to read files and write to storage/cache
- Supervisor processes to run as dedicated user

#### Development Setup (Simpler)

For development or testing, you can use the **web server user**:

```bash
# Update configs to use www-data/nginx/apache
./update-supervisor-user.sh

# Set permissions
sudo ./fix-laravel-permissions.sh
```

**Trade-offs:**
- ✅ Simpler setup
- ✅ No additional user management
- ❌ Less secure (services run as web server user)
- ❌ Mixed ownership of processes

## Laravel Deployment Example

### Production Deployment (with Dedicated User)

```bash
# 1. Install Laravel
composer create-project laravel/laravel my-app
cd my-app

# 2. Configure environment
cp .env.example .env
php artisan key:generate

# 3. Set up dedicated Laravel user (run from laravel-server-setup directory)
cd /path/to/laravel-server-setup
sudo ./setup-laravel-user.sh
# Follow prompts:
# - Username: laraveladmin (or your choice)
# - Password: [set secure password]
# - Laravel path: /var/www/html/my-app

# 4. Configure database (if installed)
# Edit .env with database credentials
nano .env

# 5. Run migrations
cd /var/www/html/my-app
php artisan migrate

# 6. Install and build frontend (if Node.js installed)
npm install
npm run build

# 7. Set up Supervisor services
cd /path/to/laravel-server-setup
sudo cp supervisor-*.conf.sample /etc/supervisor/conf.d/
# Edit each config to update Laravel paths
sudo nano /etc/supervisor/conf.d/laravel-horizon.conf
# Update: command=php /var/www/html/my-app/artisan horizon

# 8. Start services
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start all
```

### Development/Testing Deployment (Simpler)

```bash
# 1. Install Laravel
composer create-project laravel/laravel my-app
cd my-app

# 2. Configure environment
cp .env.example .env
php artisan key:generate

# 3. Set permissions using web server user
cd /path/to/laravel-server-setup
sudo ./fix-laravel-permissions.sh
# Select option 1 (Apache) or 2 (Nginx)
# Enter Laravel path when prompted

# 4. Configure database and migrate
nano .env
php artisan migrate

# 5. Install frontend dependencies
npm install
npm run dev
```

### File Permissions Guide

**Automated (Recommended):**
```bash
# Option 1: During user setup (setup-laravel-user.sh prompts for this)
sudo ./setup-laravel-user.sh

# Option 2: Standalone permissions fixer
sudo ./fix-laravel-permissions.sh
```

**Manual Setup (Production with Dedicated User):**
```bash
# Assuming user: laraveladmin, web server group: www-data
sudo chown -R laraveladmin:www-data /var/www/html/my-app
sudo find /var/www/html/my-app -type d -exec chmod 755 {} \;
sudo find /var/www/html/my-app -type f -exec chmod 644 {} \;
sudo chmod -R 775 /var/www/html/my-app/storage
sudo chmod -R 775 /var/www/html/my-app/bootstrap/cache
sudo chmod 755 /var/www/html/my-app/artisan
sudo chmod 640 /var/www/html/my-app/.env
```

**Manual Setup (Development with Web Server User):**
```bash
# Using www-data (Ubuntu/Debian)
sudo chown -R www-data:www-data /var/www/html/my-app
sudo find /var/www/html/my-app -type d -exec chmod 755 {} \;
sudo find /var/www/html/my-app -type f -exec chmod 644 {} \;
sudo chmod -R 775 /var/www/html/my-app/storage
sudo chmod -R 775 /var/www/html/my-app/bootstrap/cache
sudo chmod 755 /var/www/html/my-app/artisan
```

**Permission Reference:**
- **Directories**: 755 (rwxr-xr-x) - Owner can read/write/execute, others can read/execute
- **Files**: 644 (rw-r--r--) - Owner can read/write, others can read
- **storage/**: 775 (rwxrwxr-x) - Owner and group can write (required for logs, cache)
- **bootstrap/cache/**: 775 (rwxrwxr-x) - Owner and group can write (required for Laravel)
- **.env**: 640 (rw-r-----) - Owner can read/write, group can read, others no access
- **artisan**: 755 (rwxr-xr-x) - Executable script

**Important:** Both the owner and web server group must have write access to:
- `storage/` and all subdirectories (logs, framework, app)
- `bootstrap/cache/` (compiled services, packages, routes, config)

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
