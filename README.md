# Jitsi Meet Enterprise Installation System

[![License: WTFPL](https://img.shields.io/badge/License-WTFPL-brightgreen.svg)](http://www.wtfpl.net/about/)
[![Shell: POSIX](https://img.shields.io/badge/Shell-POSIX-blue.svg)](https://pubs.opengroup.org/onlinepubs/9699919799/)
[![OS: Linux](https://img.shields.io/badge/OS-Linux-orange.svg)](https://www.linux.org/)

A comprehensive, production-ready installation system for deploying Jitsi Meet with enterprise features including Keycloak authentication, monitoring stack, automated maintenance, and complete infrastructure management.

## 🚀 Features

### Core Components
- **Jitsi Meet** - Open source video conferencing platform
- **Keycloak** - Enterprise authentication and SSO
- **MariaDB** - Database backend
- **Valkey** - High-performance caching (Redis alternative)
- **Nginx** - Reverse proxy with SSL termination

### Monitoring & Observability
- **Prometheus** - Metrics collection
- **Grafana** - Dashboards (authenticated & public)
- **Jaeger** - Distributed tracing
- **Uptime Kuma** - Service monitoring

### Collaboration Tools
- **Etherpad** - Collaborative document editing
- **Excalidraw** - Virtual whiteboard

### Enterprise Features
- JWT authentication with Keycloak integration
- Automated SSL certificate detection
- Multi-domain support with 12 subdomains
- Automated backup system (daily/weekly/monthly)
- Health monitoring and alerting
- Resource optimization based on host capacity
- POSIX-compliant installer (works with dash/sh)

## 📋 Requirements

### System Requirements
- **OS**: Debian 10-13, Ubuntu 18.04-24.04, RHEL/CentOS/Rocky/AlmaLinux 8-9, Fedora 37-40
- **RAM**: Minimum 2GB (4GB+ recommended)
- **CPU**: Minimum 2 cores (4+ recommended)
- **Disk**: Minimum 10GB free space
- **Network**: Public IP address with domain name

### Prerequisites
- Root or sudo access
- Nginx web server installed
- Mail server (Postfix/Sendmail) on host
- Valid SSL certificates for your domain

## 🔧 Quick Installation

### One-Line Installation
```bash
curl -q -LSsf https://github.com/gistmgr/jitsi/raw/refs/heads/main/install.sh | sudo sh
```

### Manual Installation
```bash
# Clone the repository
git clone https://github.com/gistmgr/jitsi.git
cd jitsi

# Run the installer
sudo ./install.sh
```

### Installation with Parameters
```bash
sudo ./install.sh --domain meet.example.com --email admin@example.com --timezone America/New_York
```

## 📁 Directory Structure

```
/opt/jitsi/
├── .env                    # Main configuration file
├── .passwords              # Temporary password file (auto-deleted after 24h)
└── rootfs/
    ├── config/             # Service configurations
    ├── data/               # Persistent data
    ├── db/                 # Database files
    ├── logs/               # Application logs
    ├── backups/            # Automated backups
    ├── ssl/                # SSL certificates
    └── templates/          # Configuration templates
```

## 🌐 Service URLs

After installation, the following services will be available:

| Service | URL | Description |
|---------|-----|-------------|
| Main App | `https://your-domain.com/` | Jitsi Meet main interface |
| Meeting | `https://meet.your-domain.com/` | Alternative meeting URL |
| Auth Admin | `https://auth.your-domain.com/admin/` | Keycloak admin console |
| Grafana | `https://grafana.your-domain.com/` | System monitoring (authenticated) |
| Public Stats | `https://stats.your-domain.com/` | Public statistics dashboard |
| Uptime Monitor | `https://uptime.your-domain.com/` | Service health monitoring |
| Whiteboard | `https://whiteboard.your-domain.com/` | Excalidraw whiteboard |
| Etherpad | `https://pad.your-domain.com/` | Collaborative documents |
| API | `https://api.your-domain.com/` | REST API endpoint |
| Metrics | `https://metrics.your-domain.com/` | Prometheus metrics |
| Tracing | `https://trace.your-domain.com/` | Jaeger tracing UI |

## 🔐 Security

### SSL/TLS
- Automatic detection of existing SSL certificates
- Support for Let's Encrypt and commercial certificates
- Wildcard certificate support for all subdomains
- Automated certificate expiration monitoring

### Authentication
- JWT-based authentication via Keycloak
- Guest access support with lobby feature
- Rate limiting on authentication endpoints
- Brute force protection

### Network Security
- All internal services isolated on Docker network
- Reverse proxy with security headers
- Firewall configuration guidance included

## 🛠️ Maintenance

### Helper Scripts

The installer creates several maintenance scripts in `/usr/local/bin/`:

| Script | Purpose |
|--------|---------|
| `jitsi-room-cleanup` | Clean up old conference rooms |
| `jitsi-db-optimize` | Optimize databases |
| `jitsi-health-check` | Check service health |
| `jitsi-backup-daily` | Create backups |
| `jitsi-diagnose` | Troubleshooting tool |

### Automated Tasks

Cron jobs are automatically configured for:
- Hourly room cleanup
- Daily database optimization
- Daily/weekly/monthly backups
- Health checks every 5 minutes
- SSL certificate monitoring
- Log rotation and cleanup
- Container updates check

## 🔍 Configuration Options

### Command Line Options

```bash
./install.sh [OPTIONS]

Options:
  --help              Show help message
  --version           Display version information
  --dry-run           Generate configuration without installing
  --domain DOMAIN     Set the domain name
  --email EMAIL       Set administrator email
  --timezone TZ       Set timezone (default: America/New_York)
  --backup-dir PATH   Set backup directory
  --verbose           Enable verbose output
  --quiet             Suppress non-essential output
  --raw               Output raw text without colors
  --debug             Enable debug mode
```

### Environment Variables

Key configuration variables in `/opt/jitsi/.env`:
- `JITSI_DOMAIN` - Your domain name
- `JITSI_ORG_NAME` - Organization name for branding
- `JITSI_ADMIN_EMAIL` - Administrator email
- `JITSI_TIMEZONE` - System timezone
- `JITSI_ROOM_CLEANUP_INTERVAL` - Room cleanup interval (seconds)

## 🔌 Firewall Configuration

Ensure these ports are open:

| Port | Protocol | Purpose |
|------|----------|---------|
| 80 | TCP | HTTP (redirect to HTTPS) |
| 443 | TCP | HTTPS |
| 5222 | TCP | XMPP client connections |
| 5269 | TCP | XMPP server connections |
| 5347 | TCP | XMPP component connections |
| 10000 | UDP | JVB media (RTP/RTCP) |
| 4443 | TCP | JVB fallback |

Example UFW commands:
```bash
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 5222/tcp
ufw allow 5269/tcp
ufw allow 5347/tcp
ufw allow 10000/udp
ufw allow 4443/tcp
```

## 📊 Monitoring

### Grafana Dashboards
- System metrics (CPU, Memory, Disk, Network)
- Container health and resource usage
- Meeting statistics and participant counts
- Service response times

### Uptime Kuma
- Real-time service monitoring
- HTTP/HTTPS endpoint checks
- Container health monitoring
- Email alerts for downtime

### Health Checks
- Automated health checks every 5 minutes
- Service endpoint monitoring
- Container status verification
- SSL certificate expiration alerts

## 🔧 Troubleshooting

### Diagnostic Tool
Run the diagnostic script to check system status:
```bash
sudo jitsi-diagnose
```

This will check:
- System resources
- Container status
- Service endpoints
- SSL certificates
- Recent error logs

### Common Issues

1. **SSL Certificate Not Found**
   - Ensure certificates are installed in standard locations
   - Check certificate permissions (readable by nginx)

2. **Container Won't Start**
   - Check Docker service: `systemctl status docker`
   - View container logs: `docker logs jitsi-<service>`

3. **Cannot Access Services**
   - Verify firewall rules
   - Check nginx configuration: `nginx -t`
   - Ensure DNS records point to server

### Log Locations
- Installation log: `/var/log/casjaysdev/jitsi/setup.log`
- Cron logs: `/var/log/casjaysdev/jitsi/cron/`
- Container logs: `docker logs <container-name>`
- Nginx logs: `/var/log/nginx/`

## 📝 License

This project is licensed under the WTFPL License - see the [LICENSE](LICENSE) file for details.

## 👥 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 🙏 Acknowledgments

- [Jitsi](https://jitsi.org/) team for the amazing video conferencing platform
- [Keycloak](https://www.keycloak.org/) for enterprise authentication
- All the open source projects that make this possible

## 📞 Support

For issues and feature requests, please use the [GitHub issue tracker](https://github.com/gistmgr/jitsi/issues).

## 🔄 Changelog

See [CHANGELOG.md](docs/changelog.md) for version history and updates.

---

**Note**: This installer is designed for production use but always test in a staging environment first. Ensure you have proper backups before running on existing systems.