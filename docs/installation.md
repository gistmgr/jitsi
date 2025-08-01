# Installation Guide

This guide provides detailed instructions for installing Jitsi Meet Enterprise on your server.

## Prerequisites

### System Requirements

#### Minimum Requirements
- **CPU**: 2 cores
- **RAM**: 2GB
- **Disk**: 10GB free space
- **Network**: Public IP address

#### Recommended Requirements
- **CPU**: 4+ cores
- **RAM**: 8GB+
- **Disk**: 50GB+ free space
- **Network**: Dedicated server with good bandwidth

### Operating System Support

| Distribution | Versions | Status |
|-------------|----------|--------|
| Debian | 10, 11, 12, 13 | ✅ Fully Supported |
| Ubuntu | 18.04, 20.04, 22.04, 24.04 | ✅ Fully Supported |
| RHEL/CentOS | 8.x, 9.x | ✅ Fully Supported |
| Rocky Linux | 8.x, 9.x | ✅ Fully Supported |
| AlmaLinux | 8.x, 9.x | ✅ Fully Supported |
| Fedora | 37, 38, 39, 40 | ✅ Fully Supported |

### Required Software

Before running the installer, ensure these are installed:

1. **Nginx Web Server**
   ```bash
   # Debian/Ubuntu
   sudo apt update && sudo apt install -y nginx

   # RHEL/CentOS/Fedora
   sudo dnf install -y nginx
   ```

2. **Mail Server** (Postfix or Sendmail)
   ```bash
   # Debian/Ubuntu
   sudo apt install -y postfix

   # RHEL/CentOS/Fedora
   sudo dnf install -y postfix
   ```

3. **SSL Certificates**
   - Must be installed before running the installer
   - Supports Let's Encrypt or commercial certificates
   - Wildcard certificates recommended for subdomains

### SSL Certificate Setup

#### Option 1: Let's Encrypt (Recommended)
```bash
# Install certbot
sudo apt install -y certbot  # Debian/Ubuntu
sudo dnf install -y certbot  # RHEL/CentOS/Fedora

# Obtain wildcard certificate
sudo certbot certonly --standalone \
  -d your-domain.com \
  -d *.your-domain.com
```

#### Option 2: Commercial Certificate
Place your certificates in one of these locations:
- `/etc/letsencrypt/live/your-domain.com/`
- `/etc/ssl/certs/your-domain.com.crt` and `/etc/ssl/private/your-domain.com.key`
- `/etc/pki/tls/certs/your-domain.com.crt` and `/etc/pki/tls/private/your-domain.com.key`

## Installation Methods

### Method 1: One-Line Installation (Recommended)

```bash
curl -q -LSsf https://github.com/gistmgr/jitsi/raw/refs/heads/main/install.sh | sudo sh
```

### Method 2: Clone and Install

```bash
# Clone the repository
git clone https://github.com/gistmgr/jitsi.git
cd jitsi

# Make installer executable
chmod +x install.sh

# Run installer
sudo ./install.sh
```

### Method 3: Download and Install

```bash
# Download installer
wget https://github.com/gistmgr/jitsi/raw/refs/heads/main/install.sh

# Make executable
chmod +x install.sh

# Run installer
sudo ./install.sh
```

### Method 4: Automated Installation

```bash
# With parameters
sudo ./install.sh \
  --domain meet.example.com \
  --email admin@example.com \
  --timezone America/New_York \
  --quiet
```

## Installation Options

### Command Line Arguments

| Option | Description | Example |
|--------|-------------|---------|
| `--help` | Show help message | `./install.sh --help` |
| `--version` | Display version | `./install.sh --version` |
| `--dry-run` | Test without installing | `./install.sh --dry-run` |
| `--domain` | Set domain name | `./install.sh --domain meet.example.com` |
| `--email` | Set admin email | `./install.sh --email admin@example.com` |
| `--timezone` | Set timezone | `./install.sh --timezone Europe/London` |
| `--backup-dir` | Custom backup location | `./install.sh --backup-dir /backup/jitsi` |
| `--verbose` | Detailed output | `./install.sh --verbose` |
| `--quiet` | Minimal output | `./install.sh --quiet` |
| `--raw` | No colors/formatting | `./install.sh --raw` |
| `--debug` | Debug mode | `./install.sh --debug` |

### Interactive Mode

If you run the installer without parameters, it will prompt for:

1. **Domain Name**
   - Auto-detected from hostname if possible
   - Must be a valid FQDN

2. **Administrator Email**
   - Used for notifications
   - Default: admin@your-domain.com

3. **Organization Name**
   - Used for branding
   - Default: CasjaysDev MEET

## Installation Process

### What Happens During Installation

1. **System Verification**
   - OS detection and validation
   - Resource checking (CPU, RAM, disk)
   - Prerequisite verification

2. **Docker Setup**
   - Docker installation (if needed)
   - Network configuration
   - Bridge IP detection

3. **Configuration**
   - SSL certificate detection
   - Interactive configuration
   - Password generation

4. **Directory Creation**
   ```
   /opt/jitsi/
   ├── .env
   ├── .passwords
   └── rootfs/
       ├── config/
       ├── data/
       ├── db/
       ├── logs/
       └── backups/
   ```

5. **Service Deployment**
   - MariaDB database
   - Valkey cache
   - Keycloak authentication
   - Prosody XMPP server
   - Jicofo conference manager
   - JVB video bridge
   - Jitsi web server
   - Supporting services

6. **Automation Setup**
   - Helper scripts installation
   - Cron job configuration
   - Health monitoring

### Installation Duration

Typical installation times:
- Fast connection: 10-15 minutes
- Average connection: 15-25 minutes
- Slow connection: 25-40 minutes

## Post-Installation

### 1. Save Credentials

After installation, credentials are stored in:
```bash
/opt/jitsi/.passwords
```

**Important**: This file is automatically deleted after 24 hours!

### 2. Firewall Configuration

Open required ports:
```bash
# Using ufw
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 5222/tcp
sudo ufw allow 5269/tcp
sudo ufw allow 5347/tcp
sudo ufw allow 10000/udp
sudo ufw allow 4443/tcp

# Using firewalld
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=5222/tcp
sudo firewall-cmd --permanent --add-port=5269/tcp
sudo firewall-cmd --permanent --add-port=5347/tcp
sudo firewall-cmd --permanent --add-port=10000/udp
sudo firewall-cmd --permanent --add-port=4443/tcp
sudo firewall-cmd --reload
```

### 3. Verify Installation

Run the diagnostic tool:
```bash
sudo jitsi-diagnose
```

Check service status:
```bash
docker ps | grep jitsi
```

### 4. Access Services

Open your browser and navigate to:
- Main app: `https://your-domain.com`
- Keycloak: `https://auth.your-domain.com/admin/`
- Grafana: `https://grafana.your-domain.com`

## Troubleshooting Installation

### Common Issues

#### SSL Certificate Not Found
```bash
# Check certificate locations
ls -la /etc/letsencrypt/live/
ls -la /etc/ssl/certs/
ls -la /etc/pki/tls/certs/
```

#### Docker Installation Failed
```bash
# Check Docker status
systemctl status docker

# Manually install Docker
curl -fsSL https://get.docker.com | sh
```

#### Port Already in Use
```bash
# Check what's using the port
sudo netstat -tulpn | grep :443
sudo lsof -i :443
```

### Getting Help

If you encounter issues:

1. Check the installation log:
   ```bash
   tail -f /var/log/casjaysdev/jitsi/setup.log
   ```

2. Run diagnostics:
   ```bash
   sudo jitsi-diagnose
   ```

3. Report issues: [GitHub Issues](https://github.com/gistmgr/jitsi/issues)

## Next Steps

- [Configuration Guide](configuration.md) - Customize your installation
- [Architecture Overview](architecture.md) - Understand the system
- [API Reference](api.md) - Integration options