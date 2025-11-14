# Architecture & Flow Documentation

This document describes the complete workflow and architecture of the Laravel server setup scripts.

## Overview

The setup consists of **two main scripts** that work together:

1. **`server-setup.sh`** - One-time server preparation
2. **`app-setup.sh`** - Per-application deployment (reusable)

```
┌─────────────────────────────────────────────────────────────┐
│                    SERVER SETUP (One-Time)                   │
│                     server-setup.sh                          │
├─────────────────────────────────────────────────────────────┤
│ 1. Check PHP Installation                                    │
│    ├─ If missing → Offer to run setup-php84.sh             │
│    └─ If present → Verify extensions                        │
│                                                               │
│ 2. Detect Web Server & User                                  │
│    ├─ Check for Apache/Nginx                                │
│    ├─ Determine web server user (www-data/nginx/apache)     │
│    └─ Verify user exists                                     │
│                                                               │
│ 3. Install Supervisor                                        │
│    ├─ If missing → Install via package manager              │
│    └─ If present → Show version                             │
│                                                               │
│ 4. Save Configuration                                        │
│    └─ Write .laravel-server-config                          │
│        ├─ OS & Version                                       │
│        ├─ Web Server User                                    │
│        └─ Web Server Group                                   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              APPLICATION SETUP (Per Laravel App)             │
│                       app-setup.sh                           │
├─────────────────────────────────────────────────────────────┤
│ Step 1/6: USER CONFIGURATION                                │
│ ├─ Check for previous config (.laravel-app-config)         │
│ ├─ Offer to reuse previous user                            │
│ └─ If new setup:                                            │
│    ├─ [1] Development: Use web server user                 │
│    ├─ [2] Production: Create new dedicated user            │
│    │   ├─ Create user with home directory                  │
│    │   ├─ Set password                                      │
│    │   ├─ Add to sudo/wheel group                          │
│    │   ├─ Add to web server group                          │
│    │   └─ Optional: Generate SSH key (ED25519)             │
│    │       ├─ Create ~/.ssh directory (700)                │
│    │       ├─ Generate key with ssh-keygen                 │
│    │       ├─ Display public key                           │
│    │       └─ Wait for user to add to Git service         │
│    └─ [3] Production: Use existing user                    │
│        ├─ List available users                             │
│        ├─ Add to web server group if needed                │
│        └─ Check/Generate SSH key                           │
│                                                               │
│ Step 2/6: DEPLOYMENT SOURCE                                 │
│ ├─ [1] Local Directory                                      │
│ │   └─ Will prompt for path in Step 3                      │
│ └─ [2] Git Repository                                       │
│     ├─ Verify Git is installed                             │
│     ├─ Verify SSH key exists for user                      │
│     ├─ Display public key reminder                         │
│     ├─ Prompt for repository URL                           │
│     │   (e.g., git@github.com:user/repo.git)               │
│     ├─ Prompt for target directory                         │
│     ├─ Extract Git host from URL                           │
│     ├─ Add host to ~/.ssh/known_hosts                      │
│     │   (using ssh-keyscan)                                 │
│     ├─ Clone repository as user (su - $USER)               │
│     ├─ Optional: Checkout specific branch                  │
│     └─ Set LARAVEL_PATH to cloned directory                │
│                                                               │
│ Step 3/6: LARAVEL APPLICATION PATH                          │
│ ├─ If Local: Prompt for path                               │
│ ├─ If Git: Skip (path already set)                         │
│ ├─ Validate directory exists                                │
│ ├─ Check for artisan file                                   │
│ └─ Confirm it's a Laravel application                       │
│                                                               │
│ Step 4/6: SET FILE PERMISSIONS                              │
│ ├─ Set ownership: $USER:$WEB_GROUP                         │
│ ├─ Base permissions:                                        │
│ │   ├─ Directories: 755                                     │
│ │   └─ Files: 644                                           │
│ ├─ Writable directories: 775                                │
│ │   ├─ storage/                                             │
│ │   └─ bootstrap/cache/                                     │
│ ├─ Secure files:                                            │
│ │   ├─ .env: 640                                            │
│ │   └─ artisan: 755 (executable)                           │
│ └─ Verify all permissions applied                           │
│                                                               │
│ Step 5/6: LARAVEL SERVICES CONFIGURATION                    │
│ ├─ Check if Supervisor is installed                        │
│ ├─ If available:                                            │
│ │   ├─ Offer service selection:                            │
│ │   │   [1] Horizon  - Queue worker management             │
│ │   │   [2] Reverb   - WebSocket server                    │
│ │   │   [3] Pulse    - Application monitoring              │
│ │   │   [4] Schedule - Task scheduler                      │
│ │   ├─ For each selected service:                          │
│ │   │   ├─ Copy from config/supervisor-{service}.conf.sample│
│ │   │   ├─ Update user= line                               │
│ │   │   ├─ Update command paths                            │
│ │   │   ├─ Update log paths                                │
│ │   │   └─ Save to /etc/supervisor/conf.d/                │
│ │   └─ Reload Supervisor configuration                     │
│ └─ If not available: Skip                                   │
│                                                               │
│ Step 6/6: START SERVICES                                    │
│ ├─ Prompt to start services now                            │
│ ├─ If yes:                                                  │
│ │   ├─ supervisorctl reread                                │
│ │   ├─ supervisorctl update                                │
│ │   ├─ Start each service: laravel-{service}:*             │
│ │   └─ Display status                                       │
│ └─ If no: Show manual commands                             │
│                                                               │
│ SAVE CONFIGURATION                                           │
│ └─ Write .laravel-app-config                                │
│     ├─ SUPERVISOR_USER                                      │
│     ├─ ENVIRONMENT (development/production)                 │
│     ├─ LAST_APP_PATH                                        │
│     └─ DEPLOYMENT_METHOD (local/git)                        │
└─────────────────────────────────────────────────────────────┘
```

## File Structure

```
laravel-server-setup/
├── server-setup.sh              # One-time server preparation
├── app-setup.sh                 # Per-application deployment
├── setup-php84.sh               # PHP 8.4 installer (called by server-setup.sh)
├── config/                      # Configuration templates
│   ├── php.ini.sample
│   ├── apache-virtualhost.conf.sample
│   ├── nginx-virtualhost.conf.sample
│   ├── supervisor-horizon.conf.sample
│   ├── supervisor-pulse.conf.sample
│   ├── supervisor-reverb.conf.sample
│   └── supervisor-schedule.conf.sample
├── .laravel-server-config       # Generated by server-setup.sh
└── .laravel-app-config          # Generated by app-setup.sh
```

## Configuration Files

### .laravel-server-config
Generated by: `server-setup.sh`
Location: Same directory as scripts
Contents:
```bash
OS=ubuntu
OS_VERSION=22.04
WEB_SERVER_USER=www-data
WEB_SERVER_GROUP=www-data
```

### .laravel-app-config
Generated by: `app-setup.sh`
Location: Same directory as scripts
Contents:
```bash
SUPERVISOR_USER=laraveladmin
ENVIRONMENT=production
LAST_APP_PATH=/var/www/myapp
DEPLOYMENT_METHOD=git
```

## User Configuration Options

### Option 1: Development Mode
- **User**: Web server user (www-data/nginx/apache)
- **Use Case**: Development/testing environments
- **Pros**: Simple, no user management
- **Cons**: Less secure, mixed process ownership

### Option 2: Production - New Dedicated User
- **User**: Custom created user (e.g., laraveladmin, deploy)
- **Permissions**:
  - Home directory: `/home/{username}`
  - Sudo access: Member of sudo/wheel group
  - Web access: Member of web server group
  - SSH key: Optional ED25519 key generation
- **Use Case**: Production environments, Git deployments
- **Pros**: Better isolation, clear ownership, SSH key for Git
- **Cons**: Requires password setup

### Option 3: Production - Existing User
- **User**: Any existing system user
- **Requirements**: User must exist on system
- **Modifications**: Added to web server group if needed
- **Use Case**: Systems with established user accounts
- **Pros**: Use existing credentials, SSH key management
- **Cons**: None significant

## Deployment Methods

### Method 1: Local Directory
**Flow:**
1. User manually installs/copies Laravel to server
2. Script prompts for existing directory path
3. Script validates it's a Laravel app (checks for artisan)
4. Permissions are set on existing files

**Use Cases:**
- Manual Laravel installation
- Downloaded as ZIP file
- Transferred via FTP/SCP
- Local development

### Method 2: Git Repository
**Flow:**
1. User configures user with SSH key
2. Script displays SSH public key
3. User adds key to Git hosting service (GitHub/GitLab/Bitbucket)
4. Script prompts for repository URL
5. Script clones repository as the dedicated user
6. Optional branch checkout
7. Permissions automatically set

**Requirements:**
- Git must be installed (prerequisite for cloning this repo)
- SSH key must exist for the user
- User must have access to the repository

**Use Cases:**
- Production deployments
- CI/CD pipelines
- Version-controlled deployments
- Team collaboration

## Permission Model

```
Owner: dedicated-user (or www-data in dev mode)
Group: www-data (web server group)

Directories:          755 (rwxr-xr-x)
Files:                644 (rw-r--r--)
storage/:             775 (rwxrwxr-x)  # Owner + Group writable
bootstrap/cache/:     775 (rwxrwxr-x)  # Owner + Group writable
.env:                 640 (rw-r-----)  # Owner write, Group read only
artisan:              755 (rwxr-xr-x)  # Executable
```

### Why 775 for storage/ and bootstrap/cache/?
- **Owner (dedicated user)**: Needs write access for artisan commands
- **Group (web server)**: Needs write access for runtime logs/cache
- **Others**: Read/execute only for security

## SSH Key Management

### Key Generation
- **Algorithm**: ED25519 (modern, secure, shorter keys)
- **Fallback**: RSA (for compatibility)
- **Location**: `~/.ssh/id_ed25519` (or `~/.ssh/id_rsa`)
- **Permissions**:
  - Private key: 600
  - Public key: 644
  - .ssh directory: 700

### Known Hosts Management
```bash
# Automatically adds Git host
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
ssh-keyscan -H gitlab.com >> ~/.ssh/known_hosts
ssh-keyscan -H bitbucket.org >> ~/.ssh/known_hosts
```

### Git Clone Process
```bash
# Always runs as the user, never as root
su - $FINAL_USER -c "git clone 'git@github.com:user/repo.git' '/var/www/app'"
```

## Service Management

### Supervisor Configuration
Each service gets its own configuration file in `/etc/supervisor/conf.d/`:

```
laravel-horizon.conf
laravel-reverb.conf
laravel-pulse.conf
laravel-schedule.conf
```

### Configuration Template Processing
1. Copy from `config/supervisor-{service}.conf.sample`
2. Replace `user=www-data` with `user=$FINAL_USER`
3. Replace paths: `/var/www/html` → `$LARAVEL_PATH`
4. Save to `/etc/supervisor/conf.d/laravel-{service}.conf`

### Service Lifecycle
```bash
# Reload configuration
supervisorctl reread
supervisorctl update

# Start services
supervisorctl start laravel-horizon:*

# Check status
supervisorctl status

# View logs
supervisorctl tail -f laravel-horizon:laravel-horizon_00 stdout
```

## Error Handling

### server-setup.sh
- **Missing PHP**: Offers to run setup-php84.sh
- **Missing Supervisor**: Offers to install via package manager
- **Invalid web user**: Prompts for correct user
- **Permission denied**: Requires root/sudo

### app-setup.sh
- **No server config**: Exits with message to run server-setup.sh first
- **Invalid directory**: Validates path exists
- **Not Laravel app**: Warns and asks to continue
- **Missing Git**: Shows install commands for OS
- **No SSH key**: Offers to generate one
- **Clone failure**: Shows troubleshooting steps
- **User exists**: Prevents duplicate user creation

## Future Deployment Workflow

After initial setup, deployments follow this pattern:

```bash
# As the dedicated user
su - laraveladmin

# Update from Git
cd /var/www/myapp
git pull origin main

# Update dependencies
composer install --no-dev --optimize-autoloader
npm install && npm run build

# Run migrations
php artisan migrate --force

# Clear and cache
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Restart services
php artisan horizon:terminate  # Graceful
sudo supervisorctl restart laravel-reverb:*
sudo supervisorctl restart laravel-pulse:*
```

## Security Considerations

### User Isolation
- Dedicated users prevent privilege escalation
- Supervisor processes run as non-root user
- Web server has limited write access (only storage/cache)

### File Permissions
- .env is group-readable but not world-readable (640)
- Application code is world-readable for web server (644/755)
- Write access limited to necessary directories (775)

### SSH Keys
- ED25519 preferred (more secure than RSA)
- Keys never transmitted, only public key displayed
- Known hosts managed to prevent MITM attacks
- Git operations never run as root

### Sudo Access
- Dedicated users added to sudo group
- Required for server management tasks
- Can restart services independently
- Separation from web server user

## Reusability

### Multiple Applications on Same Server
The scripts support multiple Laravel applications:

1. **First app**: Full user setup, SSH keys, etc.
2. **Subsequent apps**: Offer to reuse existing user
3. **Different users**: Each app can have its own user
4. **Shared user**: Multiple apps can share one user

### Configuration Persistence
- `.laravel-app-config` remembers last user
- Offers to reuse configuration
- Reduces repetitive setup
- Each run is independent but informed

## Troubleshooting

### Common Issues

**Issue**: "Server configuration not found"
- **Cause**: server-setup.sh not run
- **Fix**: Run `sudo ./server-setup.sh` first

**Issue**: "Git is not installed"
- **Cause**: Git missing (shouldn't happen if cloned from Git)
- **Fix**: Install Git manually, then retry

**Issue**: "No SSH key found"
- **Cause**: User has no SSH key for Git access
- **Fix**: Script offers to generate one, or create manually

**Issue**: "Failed to clone repository"
- **Cause**: SSH key not added to Git service, or no repo access
- **Fix**: Verify key added to GitHub/GitLab/Bitbucket, verify access

**Issue**: "Permission denied"
- **Cause**: Not running as root/sudo
- **Fix**: Prefix command with `sudo`

**Issue**: "Supervisor not installed"
- **Cause**: server-setup.sh skipped or Supervisor install failed
- **Fix**: Run server-setup.sh again or install Supervisor manually

## Version History

### Current Version
- Server setup without Git installation (Git assumed present)
- Git-based deployments with automated SSH key management
- Organized config/ directory structure
- Scripts renamed: laravel-*-setup.sh → *-setup.sh

### Recent Changes
1. Added Git deployment support (Step 2/6)
2. Added SSH key generation for users
3. Added config/ directory for templates
4. Renamed scripts to remove "laravel" prefix
5. Removed Git installation (assumed prerequisite)

---

**Last Updated**: 2025-11-14
**Maintainer**: Repository Owner
**Status**: Active Development
