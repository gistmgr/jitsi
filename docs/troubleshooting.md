# Troubleshooting Guide

This guide helps you diagnose and resolve common issues with Jitsi Meet Enterprise.

## Quick Diagnostics

### Run System Diagnostics

```bash
sudo jitsi-diagnose
```

This will check:
- System resources
- Container status
- Service endpoints
- SSL certificates
- Recent errors

### Check Installation Logs

```bash
# View installation log
tail -f /var/log/casjaysdev/jitsi/setup.log

# Check for errors
grep ERROR /var/log/casjaysdev/jitsi/setup.log

# View recent logs
tail -n 100 /var/log/casjaysdev/jitsi/setup.log
```

## Common Issues

### 1. Installation Issues

#### SSL Certificate Not Found

**Symptoms**:
- Installation fails with "SSL certificates not found"
- Error mentions missing certificate files

**Solution**:
```bash
# Check certificate locations
ls -la /etc/letsencrypt/live/
ls -la /etc/ssl/certs/
ls -la /etc/pki/tls/certs/

# Obtain Let's Encrypt certificate
sudo certbot certonly --standalone \
  -d your-domain.com \
  -d *.your-domain.com

# Verify certificates
openssl x509 -in /path/to/cert -text -noout
```

#### SSL Certificate and Private Key Mismatch

**Symptoms**:
- Installation fails with "SSL certificate and private key do not match!"
- This commonly occurs with EC (Elliptic Curve) certificates

**Solution**:
```bash
# Check if you have an EC or RSA key
openssl pkey -in /etc/letsencrypt/live/domain/privkey.pem -noout -text | grep -E "RSA|EC"

# For RSA keys - verify match using modulus
openssl x509 -in /etc/letsencrypt/live/domain/fullchain.pem -noout -modulus | md5sum
openssl rsa -in /etc/letsencrypt/live/domain/privkey.pem -noout -modulus | md5sum

# For EC keys - verify match using public key
openssl x509 -in /etc/letsencrypt/live/domain/fullchain.pem -noout -pubkey > cert.pub
openssl ec -in /etc/letsencrypt/live/domain/privkey.pem -pubout > key.pub
diff cert.pub key.pub

# The installer now automatically handles both RSA and EC certificates
```

#### Nginx Configuration Conflicts

**Symptoms**:
- Jitsi loads wrong page (e.g., Cockpit login)
- 403 Forbidden errors
- Wrong site displays when accessing Jitsi

**Solution**:
```bash
# Check for conflicting nginx configs
ls -la /etc/nginx/vhosts.d/

# Look for default_server configs
grep -l "default_server" /etc/nginx/vhosts.d/*.conf

# Look for configs without server_name
grep -L "server_name" /etc/nginx/vhosts.d/*.conf

# Disable conflicting configs
mv /etc/nginx/vhosts.d/conflicting.conf /etc/nginx/vhosts.d/conflicting.conf.disabled

# Test and reload nginx
nginx -t && systemctl reload nginx
```

#### Docker Installation Failed

**Symptoms**:
- "Docker is not installed" error
- Docker commands not found

**Solution**:
```bash
# Check Docker status
systemctl status docker

# Install Docker manually
curl -fsSL https://get.docker.com | sh
sudo systemctl enable docker
sudo systemctl start docker

# Verify installation
docker --version
docker ps
```

#### Port Already in Use

**Symptoms**:
- "bind: address already in use" error
- Container fails to start

**Solution**:
```bash
# Find what's using the port
sudo netstat -tulpn | grep :443
sudo lsof -i :443

# Stop conflicting service
sudo systemctl stop apache2  # Example

# Or change the port in nginx config
```

### 2. Container Issues

#### Container Won't Start

**Symptoms**:
- Container exits immediately
- Container in "Restarting" state

**Diagnosis**:
```bash
# Check container status
docker ps -a | grep jitsi

# View container logs
docker logs jitsi-server
docker logs jitsi-prosody
docker logs jitsi-keycloak

# Inspect container
docker inspect jitsi-server
```

**Common Solutions**:

1. **Memory Issues**:
   ```bash
   # Check available memory
   free -h
   
   # Increase swap if needed
   sudo fallocate -l 4G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```

2. **Permission Issues**:
   ```bash
   # Fix permissions
   sudo chown -R 999:999 /opt/jitsi/rootfs/data/prosody
   sudo chmod -R 755 /opt/jitsi/rootfs/config
   ```

3. **Network Conflicts**:
   ```bash
   # Check Docker networks
   docker network ls
   docker network inspect jitsi
   
   # Recreate network if needed
   docker network rm jitsi
   docker network create jitsi
   ```

#### Container Keeps Restarting

**Solution**:
```bash
# Stop the container
docker stop jitsi-server

# Remove and recreate
docker rm jitsi-server

# Check configuration
source /opt/jitsi/.env

# Redeploy
/usr/local/bin/jitsi-deploy-server  # If exists
```

### 3. Networking Issues

#### Cannot Access Web Interface

**Symptoms**:
- Browser shows "Connection refused"
- "Site can't be reached" error

**Diagnosis**:
```bash
# Check nginx status
systemctl status nginx
nginx -t

# Check firewall
sudo ufw status
sudo iptables -L

# Test connectivity
curl -I https://localhost
curl -I https://your-domain.com
```

**Solutions**:

1. **Nginx Issues**:
   ```bash
   # Test configuration
   nginx -t
   
   # Check error logs
   tail -f /var/log/nginx/error.log
   
   # Reload nginx
   systemctl reload nginx
   ```

2. **Firewall Blocking**:
   ```bash
   # Open required ports
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw allow 10000/udp
   sudo ufw allow 4443/tcp
   ```

3. **DNS Issues**:
   ```bash
   # Check DNS resolution
   nslookup your-domain.com
   dig your-domain.com
   
   # Check local resolution
   grep your-domain /etc/hosts
   ```

#### WebSocket Connection Failed

**Symptoms**:
- "WebSocket connection failed" in browser console
- Real-time features not working

**Solution**:
```bash
# Check nginx WebSocket configuration
grep -r "upgrade" /etc/nginx/vhosts/

# Ensure these headers are present:
# proxy_set_header Upgrade $http_upgrade;
# proxy_set_header Connection "upgrade";

# Restart services
systemctl reload nginx
docker restart jitsi-server
```

### 4. Authentication Issues

#### Cannot Login to Keycloak

**Symptoms**:
- "Invalid username or password"
- Keycloak admin console not accessible

**Solution**:
```bash
# Check Keycloak logs
docker logs jitsi-keycloak

# Reset admin password
docker exec jitsi-keycloak \
  /opt/keycloak/bin/kc.sh \
  --username admin \
  --password newpassword

# Verify database connection
docker exec jitsi-mariadb \
  mysql -u root -p -e "SHOW DATABASES;"
```

#### JWT Token Errors

**Symptoms**:
- "Token validation failed"
- Users cannot join meetings

**Solution**:
```bash
# Check JWT configuration
grep JWT /opt/jitsi/.env

# Verify Prosody JWT module
docker exec jitsi-prosody \
  prosodyctl about | grep jwt

# Restart authentication chain
docker restart jitsi-keycloak
docker restart jitsi-prosody
docker restart jitsi-server
```

### 5. Media/Video Issues

#### No Audio/Video

**Symptoms**:
- Participants can't see/hear each other
- Media streams not working

**Diagnosis**:
```bash
# Check JVB status
docker logs jitsi-jvb

# Check UDP connectivity
nc -u -l 10000  # On server
nc -u server-ip 10000  # From client

# Check JVB statistics
curl http://localhost:8080/colibri/stats
```

**Solutions**:

1. **NAT/Firewall Issues**:
   ```bash
   # Ensure UDP 10000 is open
   sudo ufw allow 10000/udp
   
   # Check NAT configuration
   docker exec jitsi-jvb \
     cat /etc/jitsi/videobridge/sip-communicator.properties
   ```

2. **TURN Server**:
   ```bash
   # Deploy TURN server if behind strict NAT
   docker run -d \
     --name jitsi-coturn \
     --network host \
     -e TURN_SECRET=$JITSI_TURN_SECRET \
     instrumentisto/coturn
   ```

#### Poor Video Quality

**Solution**:
```bash
# Increase bandwidth limits
docker exec jitsi-server \
  sed -i 's/maxBitratesVideo:.*/maxBitratesVideo: { low: 200000, standard: 500000, high: 1500000 }/' \
  /config/web/config.js

# Restart
docker restart jitsi-server
```

### 6. Performance Issues

#### High CPU Usage

**Diagnosis**:
```bash
# Check container resource usage
docker stats

# Check system load
top
htop

# Check JVB performance
docker exec jitsi-jvb \
  jcmd $(pgrep -f jvb) VM.native_memory summary
```

**Solutions**:
```bash
# Limit container resources
docker update --cpus="2.0" jitsi-jvb
docker update --memory="2g" jitsi-jvb

# Enable CPU pinning
docker update --cpuset-cpus="0-3" jitsi-jvb
```

#### Memory Leaks

**Solution**:
```bash
# Set up automatic container restart
cat > /etc/cron.d/jitsi-restart << EOF
0 3 * * * root docker restart jitsi-jvb jitsi-jicofo
EOF

# Monitor memory usage
watch -n 5 'docker stats --no-stream'
```

### 7. Storage Issues

#### Disk Space Full

**Symptoms**:
- "No space left on device" errors
- Services failing to start

**Solution**:
```bash
# Check disk usage
df -h
du -sh /opt/jitsi/*

# Clean up logs
find /var/log/casjaysdev/jitsi -name "*.log" -mtime +7 -delete

# Clean up old recordings
find /opt/jitsi/rootfs/data/recordings -name "*.webm" -mtime +30 -delete

# Clean up Docker
docker system prune -a
```

#### Backup Failures

**Solution**:
```bash
# Check backup logs
tail -f /var/log/casjaysdev/jitsi/cron/backup.log

# Run backup manually
/usr/local/bin/jitsi-backup-daily daily

# Check backup directory permissions
ls -la /opt/jitsi/rootfs/backups/
```

### 8. Certificate Issues

#### Certificate Expired

**Symptoms**:
- Browser shows security warning
- "NET::ERR_CERT_DATE_INVALID"

**Solution**:
```bash
# Check certificate expiration
openssl x509 -in /path/to/cert -noout -dates

# Renew Let's Encrypt certificate
certbot renew

# Restart nginx
systemctl reload nginx
```

#### Certificate Mismatch

**Solution**:
```bash
# Verify certificate matches key
openssl x509 -noout -modulus -in cert.pem | md5sum
openssl rsa -noout -modulus -in key.pem | md5sum

# Check certificate domain
openssl x509 -in cert.pem -text -noout | grep CN
```

## Health Monitoring

### Set Up Continuous Monitoring

```bash
# Enable detailed health checks
sed -i 's/*/5/*/1/' /etc/cron.d/jitsi  # Every minute

# Watch health check logs
tail -f /var/log/casjaysdev/jitsi/cron/health-check.log

# Set up alerts
echo 'your-email@example.com' > /opt/jitsi/.alerts
```

### Monitor Resource Usage

```bash
# Create monitoring script
cat > /usr/local/bin/jitsi-monitor << 'EOF'
#!/bin/sh
echo "=== Jitsi Resource Monitor ==="
echo "Timestamp: $(date)"
echo ""
echo "Container Status:"
docker ps | grep jitsi
echo ""
echo "Resource Usage:"
docker stats --no-stream | grep jitsi
echo ""
echo "Active Conferences:"
curl -s http://localhost:8080/colibri/stats | jq .conferences
EOF

chmod +x /usr/local/bin/jitsi-monitor
```

## Advanced Diagnostics

### Enable Debug Logging

```bash
# Enable debug for Prosody
docker exec jitsi-prosody \
  sed -i 's/info/debug/g' /config/prosody.cfg.lua
docker restart jitsi-prosody

# Enable debug for JVB
docker exec jitsi-jvb \
  sed -i 's/INFO/FINE/g' /etc/jitsi/videobridge/logging.properties
docker restart jitsi-jvb
```

### Packet Capture

```bash
# Capture WebRTC traffic
tcpdump -i any -w jitsi.pcap 'port 10000'

# Analyze with tshark
tshark -r jitsi.pcap -Y "stun || rtp"
```

### Database Queries

```bash
# Check active rooms
docker exec jitsi-mariadb \
  mysql -u root -p$JITSI_MARIADB_ROOT_PASSWORD jitsi \
  -e "SELECT * FROM rooms WHERE active = 1;"

# Check user sessions
docker exec jitsi-mariadb \
  mysql -u root -p$JITSI_MARIADB_ROOT_PASSWORD keycloak \
  -e "SELECT * FROM user_session LIMIT 10;"
```

## Getting Help

### Collect Diagnostic Information

```bash
# Create diagnostic bundle
cat > /tmp/jitsi-diag.sh << 'EOF'
#!/bin/bash
DIAG_DIR="/tmp/jitsi-diagnostics-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$DIAG_DIR"

# System info
uname -a > "$DIAG_DIR/system.txt"
free -h >> "$DIAG_DIR/system.txt"
df -h >> "$DIAG_DIR/system.txt"

# Docker info
docker ps -a > "$DIAG_DIR/docker-ps.txt"
docker network ls >> "$DIAG_DIR/docker-ps.txt"

# Logs
tail -n 1000 /var/log/casjaysdev/jitsi/setup.log > "$DIAG_DIR/setup.log"
for container in $(docker ps --format '{{.Names}}' | grep jitsi); do
  docker logs --tail 500 "$container" > "$DIAG_DIR/${container}.log" 2>&1
done

# Configuration (sanitized)
grep -v PASSWORD /opt/jitsi/.env > "$DIAG_DIR/env.txt"

# Create archive
tar -czf "$DIAG_DIR.tar.gz" -C /tmp "$(basename $DIAG_DIR)"
echo "Diagnostic bundle created: $DIAG_DIR.tar.gz"
EOF

bash /tmp/jitsi-diag.sh
```

### Report Issues

When reporting issues, include:
1. Diagnostic bundle
2. Steps to reproduce
3. Expected behavior
4. Actual behavior
5. Browser console errors
6. Network trace (if applicable)

Report at: [GitHub Issues](https://github.com/gistmgr/jitsi/issues)

## Maintenance Commands

### Emergency Recovery

```bash
# Stop all services
docker stop $(docker ps -q --filter name=jitsi)

# Backup current state
tar -czf /tmp/jitsi-emergency-backup.tar.gz /opt/jitsi

# Reset to clean state
docker rm $(docker ps -aq --filter name=jitsi)
docker network rm jitsi

# Reinstall
cd /opt/jitsi
./install.sh
```

### Performance Tuning

```bash
# Optimize database
/usr/local/bin/jitsi-db-optimize

# Clear caches
docker exec jitsi-valkey valkey-cli FLUSHALL

# Restart services in order
for service in mariadb valkey keycloak prosody jicofo jvb server; do
  docker restart jitsi-$service
  sleep 10
done
```

## Next Steps

- [Configuration](configuration.md) - Fine-tune settings
- [Architecture](architecture.md) - Understand the system
- [API Reference](api.md) - Integration options