# PHP 8.4 Setup Script

Automated installation script for PHP 8.4 with support for Ubuntu and Alpine Linux.

## Quick Start

### Complete Laravel Server Setup (2 Simple Steps)

```bash
# 1. Prepare server (one-time setup)
chmod +x server-setup.sh
sudo ./server-setup.sh
# Installs PHP 8.4 and web server (if needed)
# Installs Supervisor

# 2. Deploy your Laravel application (run for each app)
chmod +x app-setup.sh
sudo ./app-setup.sh
# Choose user configuration (development/production)
# SSH key generation for Git access
# Choose deployment: Local directory OR Git repository
# Select services (Horizon, Reverb, Pulse, Schedule)
```

That's it! Your Laravel application is now configured with proper permissions and services.

> 📘 **For detailed architecture and workflow documentation, see [FLOW.md](FLOW.md)**

## Repository Contents

### Main Setup Scripts (Recommended)
- **`server-setup.sh`** - **⭐ ONE-TIME** server preparation (PHP, web server, Supervisor)
- **`app-setup.sh`** - **Per-application** deployment (user, permissions, services)

### Documentation
- **`README.md`** - Complete setup guide and usage instructions
- **`FLOW.md`** - Architecture flow and technical documentation

### PHP & Web Server Setup
- **`setup-php84.sh`** - PHP 8.4 installation script (called by server-setup.sh)

### Configuration Templates (`config/`)
- **`php.ini.sample`** - Production-ready PHP configuration
- **`apache-virtualhost.conf.sample`** - Apache virtual host template
- **`nginx-virtualhost.conf.sample`** - Nginx server block template
- **`supervisor-reverb.conf.sample`** - Supervisor config for Laravel Reverb WebSocket server
- **`supervisor-horizon.conf.sample`** - Supervisor config for Laravel Horizon queue worker
- **`supervisor-pulse.conf.sample`** - Supervisor config for Laravel Pulse monitoring
- **`supervisor-schedule.conf.sample`** - Supervisor config for Laravel task scheduler

## Features

- **OS Support**: Ubuntu and Alpine Linux
- **PHP 8.4**: Latest PHP version with common extensions
- **Git Deployment**: Automated SSH key generation and repository cloning
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
- **`config/php.ini.sample`** - Production-ready PHP 8.4 configuration with security best practices
- **`config/apache-virtualhost.conf.sample`** - Apache virtual host configuration for Laravel/PHP apps
- **`config/nginx-virtualhost.conf.sample`** - Nginx server block configuration for Laravel/PHP apps

### Laravel Services (Supervisor)
- **`config/supervisor-reverb.conf.sample`** - Supervisor config for Laravel Reverb (WebSocket server)
- **`config/supervisor-horizon.conf.sample`** - Supervisor config for Laravel Horizon (queue management)
- **`config/supervisor-pulse.conf.sample`** - Supervisor config for Laravel Pulse (application monitoring)
- **`config/supervisor-schedule.conf.sample`** - Supervisor config for Laravel Scheduler (task scheduling)

See the [Configuration](#configuration) section for detailed instructions on using these files.

## Requirements

- Root/sudo access
- Supported OS: Ubuntu 20.04+, Debian 11+, or Alpine Linux
- Internet connection
- Git (for cloning this repository and Git-based deployments)

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
sudo cp config/php.ini.sample /etc/php/8.4/fpm/php.ini

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
sudo cp config/apache-virtualhost.conf.sample /etc/apache2/sites-available/your-app.conf

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
sudo cp config/nginx-virtualhost.conf.sample /etc/nginx/sites-available/your-app

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

#### Automated Setup (RECOMMENDED)

**Step 1: Server Preparation (One-Time)**

```bash
chmod +x server-setup.sh
sudo ./server-setup.sh
```

This script will:
- Check and install PHP 8.4 if needed (runs setup-php84.sh)
- Detect your web server (Apache/Nginx)
- Install Supervisor if needed
- Save server configuration

Note: Git is assumed to be already installed (required to clone this repository)

**Step 2: Application Deployment (Per Laravel App)**

```bash
chmod +x app-setup.sh
sudo ./app-setup.sh
```

This script will:
- Let you choose user configuration:
  - **Development**: Use web server user (simpler)
  - **Production**: Create new dedicated user OR use existing user
- Optionally generate SSH keys for Git access
- Let you choose deployment source:
  - **Local directory**: Use existing Laravel installation
  - **Git repository**: Clone from GitHub/GitLab/Bitbucket
- Set correct ownership and permissions for your Laravel app
- Let you select which services to enable (Horizon, Reverb, Pulse, Schedule)
- Copy and configure supervisor configs with correct user and paths
- Start the selected services

**Benefits:**
- ✅ Complete server setup in 2 commands
- ✅ Reusable for multiple Laravel applications
- ✅ Automatic user and permission management
- ✅ Service selection per application
- ✅ Production and development modes

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
sudo cp config/supervisor-horizon.conf.sample /etc/supervisor/conf.d/laravel-horizon.conf

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
sudo cp config/supervisor-horizon.conf.sample /etc/supervisor/conf.d/laravel-horizon.conf
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
sudo cp config/supervisor-reverb.conf.sample /etc/supervisor/conf.d/laravel-reverb.conf
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
sudo cp config/supervisor-pulse.conf.sample /etc/supervisor/conf.d/laravel-pulse.conf
sudo nano /etc/supervisor/conf.d/laravel-pulse.conf
sudo supervisorctl reread && sudo supervisorctl update
sudo supervisorctl start laravel-pulse:*

# Access dashboard: https://your-domain.com/pulse
```

**Laravel Scheduler:**

```bash
# Option 1: Using Supervisor (this config)
sudo cp config/supervisor-schedule.conf.sample /etc/supervisor/conf.d/laravel-schedule.conf
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

### Complete Deployment Workflow

This repository supports **two deployment methods**:

#### Method 1: Git Repository Deployment (Recommended for Production)

Deploy directly from GitHub, GitLab, or Bitbucket with automatic SSH key setup:

```bash
# 1. ONE-TIME: Prepare server (if not done already)
cd /path/to/laravel-server-setup
sudo ./server-setup.sh
# This installs PHP, web server, and Supervisor

# 2. Deploy from Git repository
sudo ./app-setup.sh

# Follow the prompts:
# Step 1/6: Choose user (Production - Create new dedicated user)
#   - Creates user with sudo access
#   - Generates SSH key automatically
#   - Displays public key to add to GitHub/GitLab/Bitbucket

# Step 2/6: Choose deployment source (Git repository)
#   - Enter repository URL: git@github.com:username/myapp.git
#   - Enter target directory: /var/www/myapp
#   - Repository is cloned automatically
#   - Optional: checkout specific branch

# Step 3/6: Validates Laravel application
# Step 4/6: Sets proper permissions automatically
# Step 5/6: Select services (e.g., 1 2 4 for Horizon, Reverb, Schedule)
# Step 6/6: Services are started

# 3. Configure environment (inside cloned repository)
cd /var/www/myapp
cp .env.example .env
nano .env
# Set DB_HOST, DB_DATABASE, DB_USERNAME, DB_PASSWORD, etc.
php artisan key:generate
php artisan migrate

# 4. Install and build frontend (if Node.js installed)
npm install
npm run build  # For production

# 5. Done! Your Git-deployed app is running
sudo supervisorctl status
```

**Future deployments from Git (as your dedicated user):**
```bash
# Switch to your Laravel user
su - laraveladmin  # or your chosen username

# Update from Git
cd /var/www/myapp
git pull origin main

# Update dependencies and rebuild
composer install --no-dev --optimize-autoloader
npm install && npm run build
php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Restart services
php artisan horizon:terminate  # Graceful restart for Horizon
sudo supervisorctl restart laravel-reverb:*
sudo supervisorctl restart laravel-pulse:*
```

**Benefits of Git Deployment:**
- ✅ Automated SSH key generation and setup
- ✅ Direct deployment from your repository
- ✅ Easy updates with `git pull`
- ✅ Version control integration
- ✅ Proper file ownership and permissions
- ✅ Branch management support

#### Method 2: Local Directory Deployment

Deploy from an existing directory on the server:

```bash
# 1. ONE-TIME: Prepare server (if not done already)
cd /path/to/laravel-server-setup
sudo ./server-setup.sh

# 2. Install Laravel locally
cd /var/www
composer create-project laravel/laravel my-app
cd my-app

# 3. Configure environment
cp .env.example .env
php artisan key:generate
nano .env  # Configure database, etc.
php artisan migrate

# 4. Install and build frontend (if Node.js installed)
npm install
npm run build  # For production

# 5. Deploy with app setup script
cd /path/to/laravel-server-setup
sudo ./app-setup.sh

# Follow the prompts:
# Step 1/6: Choose user (Development or Production)
# Step 2/6: Choose deployment source (Local directory)
# Step 3/6: Enter path: /var/www/my-app
# Step 4/6: Permissions set automatically
# Step 5/6: Select services
# Step 6/6: Services started

# 6. Done! Services are configured and running
sudo supervisorctl status
```

**For additional Laravel apps on the same server:**
Just run `sudo ./app-setup.sh` again - it will let you choose user configuration and deployment method for each app!

### SSH Key Management for Git

The setup script automatically handles SSH keys, but here's what happens:

**For new users (Production - Create new dedicated user):**
1. User is created with home directory and sudo access
2. Script offers to generate SSH key (ED25519)
3. Public key is displayed with instructions
4. You add the key to GitHub/GitLab/Bitbucket
5. Git deployment becomes available

**For existing users (Production - Use existing user):**
1. Script checks if SSH key already exists
2. If yes: offers to display it
3. If no: offers to generate new key
4. Same workflow as new users

**Supported Git Hosting Services:**
- **GitHub**: Settings → SSH and GPG keys → New SSH key
- **GitLab**: Preferences → SSH Keys → Add new key
- **Bitbucket**: Personal settings → SSH keys → Add key

**Manual SSH Key Display:**
```bash
# If you need to view your SSH public key later
cat ~/.ssh/id_ed25519.pub
# or
cat ~/.ssh/id_rsa.pub
```

### Manual Deployment (Advanced)

If you prefer to configure manually without the automated scripts:

```bash
# 1. Install Laravel
composer create-project laravel/laravel my-app
cd my-app
cp .env.example .env
php artisan key:generate

# 2. Configure database and run migrations
nano .env
php artisan migrate
npm install && npm run build

# 3. Set permissions manually
# For development (web server user):
sudo chown -R www-data:www-data /var/www/my-app
sudo chmod -R 775 /var/www/my-app/storage
sudo chmod -R 775 /var/www/my-app/bootstrap/cache

# For production (dedicated user):
sudo chown -R youruser:www-data /var/www/my-app
sudo chmod -R 775 /var/www/my-app/storage
sudo chmod -R 775 /var/www/my-app/bootstrap/cache

# 4. Copy and configure supervisor files
sudo cp config/supervisor-horizon.conf.sample /etc/supervisor/conf.d/laravel-horizon.conf
sudo nano /etc/supervisor/conf.d/laravel-horizon.conf
# Update user= and paths

sudo supervisorctl reread && sudo supervisorctl update
sudo supervisorctl start all
```

### File Permissions Guide

**Automated (Recommended):**
```bash
# Permissions are automatically configured by app-setup.sh
sudo ./app-setup.sh
# This handles all user, ownership, and permission configuration
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
