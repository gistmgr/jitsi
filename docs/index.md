# Jitsi Meet Enterprise Documentation

Welcome to the Jitsi Meet Enterprise installation system documentation. This comprehensive guide will help you deploy a production-ready Jitsi Meet instance with enterprise features.

## What is Jitsi Meet Enterprise?

Jitsi Meet Enterprise is an automated installation system that deploys:

- **Jitsi Meet** - Open source video conferencing
- **Keycloak** - Enterprise authentication and SSO
- **Full Monitoring Stack** - Prometheus, Grafana, Jaeger, Uptime Kuma
- **Collaboration Tools** - Etherpad and Excalidraw
- **Automated Maintenance** - Backups, cleanup, health checks

## Key Features

### 🔒 Enterprise Security
- JWT authentication via Keycloak
- SSL/TLS with automatic certificate detection
- Network isolation with Docker
- Rate limiting and brute force protection

### 📊 Complete Monitoring
- Real-time metrics with Prometheus
- Beautiful dashboards with Grafana
- Distributed tracing with Jaeger
- Uptime monitoring with Uptime Kuma

### 🤖 Automation
- One-line installation
- Automated backups (daily/weekly/monthly)
- Self-healing with health checks
- Automatic cleanup and optimization

### 🚀 Production Ready
- Supports 10-13 containerized services
- Resource optimization based on host
- Multi-domain with 12 subdomains
- POSIX compliant installer

## Quick Start

### One-Line Installation

```bash
curl -q -LSsf https://github.com/gistmgr/jitsi/raw/refs/heads/main/install.sh | sudo sh
```

### Requirements

- **OS**: Debian 10+, Ubuntu 18.04+, RHEL/CentOS 8+, Fedora 37+
- **Resources**: 2GB RAM, 2 CPU cores, 10GB disk minimum
- **Network**: Public IP with domain name
- **Prerequisites**: Nginx, mail server, SSL certificates

## Architecture Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│     Nginx       │────▶│   Jitsi Meet    │────▶│    Prosody      │
│  (Reverse Proxy)│     │   (Web Server)  │     │  (XMPP Server)  │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│    Keycloak     │     │     Jicofo      │     │      JVB        │
│     (Auth)      │     │ (Conference Mgr)│     │  (Video Bridge) │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│    MariaDB      │     │     Valkey      │     │   Monitoring    │
│   (Database)    │     │    (Cache)      │     │     Stack       │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

## Service URLs

After installation, access your services at:

| Service | URL |
|---------|-----|
| Main Application | `https://your-domain.com/` |
| Keycloak Admin | `https://auth.your-domain.com/admin/` |
| Grafana Dashboard | `https://grafana.your-domain.com/` |
| Public Statistics | `https://stats.your-domain.com/` |
| Uptime Monitor | `https://uptime.your-domain.com/` |
| Whiteboard | `https://whiteboard.your-domain.com/` |
| Etherpad | `https://pad.your-domain.com/` |

## Next Steps

- [Installation Guide](installation.md) - Detailed installation instructions
- [Configuration](configuration.md) - Customize your deployment
- [Architecture](architecture.md) - Technical deep dive
- [Troubleshooting](troubleshooting.md) - Common issues and solutions

## Support

- **Issues**: [GitHub Issues](https://github.com/gistmgr/jitsi/issues)
- **Documentation**: [ReadTheDocs](https://jitsi-enterprise.readthedocs.io)
- **License**: [WTFPL](http://www.wtfpl.net/about/)

---

*Built with ❤️ by Jason Hempstead - Casjays Developments*