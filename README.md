# PHP 8.4 Setup Script

Automated installation script for PHP 8.4 with support for Ubuntu and Alpine Linux.

## Features

- **OS Support**: Ubuntu and Alpine Linux
- **PHP 8.4**: Latest PHP version with common extensions
- **All Database Clients**: MySQL and PostgreSQL extensions always installed
- **Redis Extension**: Always installed for caching support
- **Interactive Setup** (Ubuntu only):
  - Web server selection (Apache or Nginx)
  - Database server installation (MySQL Server, PostgreSQL Server, or None)
  - Redis server installation option
- **Automatic Composer Installation**
- **Complete Laravel/PHP Application Stack**

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

# Check web server (Ubuntu)
# For Apache:
sudo systemctl status apache2

# For Nginx:
sudo systemctl status nginx
sudo systemctl status php8.4-fpm
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
```

## Nginx Configuration Example

For Laravel/PHP applications on Nginx, create a site configuration:

```nginx
server {
    listen 80;
    server_name example.com;
    root /var/www/html/my-app/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
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
5. **Updates**: Regularly update packages for security patches

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
