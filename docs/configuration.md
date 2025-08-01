# Configuration Guide

This guide covers all configuration options for Jitsi Meet Enterprise.

## Configuration Files

### Main Configuration File

The primary configuration file is located at:
```
/opt/jitsi/.env
```

This file contains all environment variables used by the system.

### File Structure

```bash
# Organization and Branding
JITSI_ORG_NAME="Your Organization"
JITSI_DOMAIN="meet.example.com"
JITSI_ADMIN_EMAIL="admin@example.com"
JITSI_TIMEZONE="America/New_York"

# Authentication Configuration
JITSI_KEYCLOAK_ADMIN_USER="administrator@example.com"
JITSI_KEYCLOAK_ADMIN_PASSWORD="secure-password"
JITSI_DEFAULT_ADMIN_USERNAME="administrator"
JITSI_JWT_APP_SECRET="jwt-secret-key"

# ... additional settings
```

## Configuration Categories

### 1. Organization Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `JITSI_ORG_NAME` | Organization name for branding | CasjaysDev MEET |
| `JITSI_DOMAIN` | Primary domain name | (required) |
| `JITSI_ADMIN_EMAIL` | Administrator email | admin@domain |
| `JITSI_TIMEZONE` | System timezone | America/New_York |

### 2. Authentication Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `JITSI_KEYCLOAK_ADMIN_USER` | Keycloak admin username | administrator@domain |
| `JITSI_KEYCLOAK_ADMIN_PASSWORD` | Keycloak admin password | (generated) |
| `JITSI_DEFAULT_ADMIN_USERNAME` | Default admin username | administrator |
| `JITSI_JWT_APP_SECRET` | JWT signing secret | (generated) |

### 3. Mail Server Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `JITSI_USE_HOST_MAILSERVER` | Use host mail server | true |
| `JITSI_SMTP_HOST` | SMTP server address | 172.17.0.1 |
| `JITSI_SMTP_PORT` | SMTP server port | 25 |
| `JITSI_SMTP_AUTH` | Enable SMTP auth | false |
| `JITSI_SMTP_TLS` | Enable SMTP TLS | false |
| `JITSI_SMTP_FROM_NAME` | From name in emails | $JITSI_ORG_NAME |
| `JITSI_SMTP_FROM_EMAIL` | From email address | no-reply@domain |

### 4. Docker Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `JITSI_DOCKER_NETWORK_NAME` | Docker network name | jitsi |
| `JITSI_DOCKER_BRIDGE_IP` | Docker bridge IP | 172.17.0.1 |
| `JITSI_CONTAINER_MEMORY_LIMIT` | Container memory limit | (auto-detected) |
| `JITSI_SHARED_MEMORY_SIZE` | Shared memory size | (auto-detected) |

### 5. Service Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `JITSI_ROOM_CLEANUP_INTERVAL` | Room cleanup interval (seconds) | 604800 (7 days) |
| `JITSI_ANONYMOUS_RATE_LIMIT` | Anonymous user rate limit | 5 req/s |
| `JITSI_AUTHENTICATED_RATE_LIMIT` | Authenticated user rate limit | 20 req/s |

## Advanced Configuration

### Nginx Configuration

Custom nginx configurations can be added to:
```
/etc/nginx/vhosts/
```

Each service has its own vhost file:
- `domain.conf` - Main Jitsi Meet
- `auth.domain.conf` - Keycloak
- `grafana.domain.conf` - Grafana
- etc.

### Container Configuration

To customize container settings, modify the deployment scripts in:
```
/usr/local/bin/jitsi-*
```

### Database Configuration

MariaDB settings:
```bash
# Access database
docker exec -it jitsi-mariadb mysql -u root -p

# Database credentials
Database: jitsi
User: jitsi
Password: (see .env file)
```

## Jitsi Meet Specific Settings

### Video Quality

Edit `/opt/jitsi/rootfs/config/jitsi/config.js`:
```javascript
// Video constraints
constraints: {
    video: {
        height: {
            ideal: 720,
            max: 1080,
            min: 180
        }
    }
}
```

### Audio Settings

```javascript
// Enable noise suppression
enableNoisyMicDetection: true,

// Enable echo cancellation
enableTalkWhileMuted: false,

// Audio quality
audioQuality: {
    stereo: false,
    opusMaxAverageBitrate: 28000
}
```

### Recording Configuration

```javascript
// Recording settings
recordingService: {
    enabled: true,
    sharingEnabled: true
}

// Live streaming
liveStreamingEnabled: true,
fileRecordingsEnabled: true
```

## Keycloak Configuration

### Accessing Keycloak Admin

1. Navigate to: `https://auth.your-domain.com/admin/`
2. Login with admin credentials from `.passwords` file
3. Create new realm for Jitsi

### Creating Jitsi Realm

1. Click "Add realm"
2. Name: `jitsi`
3. Enable user registration
4. Configure email settings

### Client Configuration

1. Create new client: `jitsi-meet`
2. Client Protocol: `openid-connect`
3. Access Type: `public`
4. Valid Redirect URIs: `https://your-domain.com/*`

## Monitoring Configuration

### Grafana Dashboards

Access Grafana at: `https://grafana.your-domain.com`

Default dashboards:
- System Overview
- Container Metrics
- Jitsi Statistics
- Network Traffic

### Adding Custom Dashboards

1. Login to Grafana
2. Create → Dashboard
3. Add panels for metrics
4. Save dashboard

### Prometheus Configuration

Configuration file: `/opt/jitsi/rootfs/config/prometheus/prometheus.yml`

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'jitsi'
    static_configs:
      - targets: ['jitsi-server:8888']
```

### Uptime Kuma Setup

1. Access: `https://uptime.your-domain.com`
2. Create monitors for each service
3. Configure notifications

## Backup Configuration

### Backup Schedule

Edit `/etc/cron.d/jitsi`:
```bash
# Daily backup at 4 AM
0 4 * * * root /usr/local/bin/jitsi-backup-daily daily

# Weekly backup Sunday at 2 AM
0 2 * * 0 root /usr/local/bin/jitsi-backup-daily weekly
```

### Backup Retention

Modify `/usr/local/bin/jitsi-backup-daily`:
```bash
# Daily backups kept for 6 days
find "$JITSI_BACKUP_DIR/daily" -name "*.tar.gz" -mtime +6 -delete

# Weekly backups kept for 3 weeks
find "$JITSI_BACKUP_DIR/weekly" -name "*.tar.gz" -mtime +21 -delete
```

### Custom Backup Location

```bash
# Edit .env file
JITSI_BACKUP_DIR="/custom/backup/path"

# Restart services
docker restart jitsi-server
```

## Security Configuration

### SSL/TLS Settings

Nginx SSL configuration in vhost files:
```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers HIGH:!aNULL:!MD5;
ssl_prefer_server_ciphers on;
ssl_session_cache shared:SSL:10m;
```

### Rate Limiting

Adjust in nginx vhost files:
```nginx
# Authentication endpoints
limit_req_zone $binary_remote_addr zone=jitsi_auth:10m rate=5r/s;

# API endpoints
limit_req_zone $binary_remote_addr zone=jitsi_api:10m rate=20r/s;
```

### Firewall Rules

Additional security with iptables:
```bash
# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow specific ports only
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p udp --dport 10000 -j ACCEPT
```

## Performance Tuning

### JVB Configuration

Edit JVB settings:
```bash
# Increase memory for JVB
docker stop jitsi-jvb
docker rm jitsi-jvb

# Redeploy with more memory
docker run -d \
  --name jitsi-jvb \
  --memory 4g \
  # ... other options
```

### Prosody Optimization

```lua
-- /opt/jitsi/rootfs/config/prosody/prosody.cfg.lua
c2s_tcp_keepalives = true
s2s_tcp_keepalives = true
limits = {
  c2s = {
    rate = "10kb/s";
  };
}
```

## Troubleshooting Configuration

### Validation

Check configuration syntax:
```bash
# Validate .env file
source /opt/jitsi/.env && echo "Configuration valid"

# Test nginx config
nginx -t

# Check Docker networks
docker network ls
```

### Common Issues

1. **Invalid Domain**
   - Ensure domain is FQDN
   - Check DNS resolution

2. **Password Issues**
   - Passwords must not contain special shell characters
   - Use generated passwords when possible

3. **Network Conflicts**
   - Check Docker bridge IP
   - Ensure no IP conflicts

## Applying Configuration Changes

After making changes:

1. **Environment Variables**
   ```bash
   source /opt/jitsi/.env
   ```

2. **Restart Services**
   ```bash
   docker restart jitsi-server
   docker restart jitsi-prosody
   # ... etc
   ```

3. **Nginx Changes**
   ```bash
   nginx -t && systemctl reload nginx
   ```

## Next Steps

- [Architecture Overview](architecture.md) - System design
- [API Reference](api.md) - Integration options
- [Troubleshooting](troubleshooting.md) - Common issues