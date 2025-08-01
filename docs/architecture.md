# System Architecture

This document provides a comprehensive overview of the Jitsi Meet Enterprise architecture.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                           Internet Users                             │
└─────────────────────────────────┬───────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         Nginx Reverse Proxy                          │
│                    (SSL Termination, Load Balancing)                 │
└─────────────────────────────────┬───────────────────────────────────┘
                                  │
        ┌─────────────────────────┴─────────────────────────┐
        │                                                   │
        ▼                                                   ▼
┌───────────────────┐                               ┌───────────────────┐
│   Jitsi Meet      │                               │    Keycloak       │
│   Web Server      │◄──────── JWT Auth ───────────►│  (Authentication) │
│   (Port 8000)     │                               │   (Port 8080)     │
└───────┬───────────┘                               └───────────────────┘
        │                                                   │
        │                                                   ▼
        │                                           ┌───────────────────┐
        │                                           │     MariaDB       │
        │                                           │   (Databases)     │
        │                                           │   (Port 3306)     │
        │                                           └───────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────────────┐
│                          XMPP Infrastructure                       │
├───────────────────┬───────────────────┬───────────────────────────┤
│     Prosody       │      Jicofo       │          JVB              │
│  (XMPP Server)    │  (Conference Mgr) │    (Video Bridge)        │
│  (Ports 5222,     │   (Port 8888)     │   (Port 10000 UDP,       │
│   5269, 5347)     │                   │    4443 TCP)             │
└───────────────────┴───────────────────┴───────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────────────┐
│                       Supporting Services                          │
├─────────────┬──────────────┬──────────────┬──────────────────────┤
│  Etherpad   │  Excalidraw  │    Valkey    │   Monitoring Stack   │
│ (Port 9001) │ (Port 3003)  │ (Port 6379)  │  (Various Ports)     │
└─────────────┴──────────────┴──────────────┴──────────────────────┘
```

## Component Details

### 1. Nginx Reverse Proxy

**Purpose**: Entry point for all HTTP/HTTPS traffic

**Responsibilities**:
- SSL/TLS termination
- Request routing to backend services
- Load balancing
- Security headers
- Rate limiting
- Static content caching

**Configuration**:
- 12 vhost configurations (one per subdomain)
- WebSocket support for real-time features
- Gzip compression enabled

### 2. Jitsi Meet Web Server

**Purpose**: Main web application interface

**Components**:
- React-based web UI
- WebRTC implementation
- Conference management
- User interface for meetings

**Integration Points**:
- Authenticates users via Keycloak JWT
- Communicates with Prosody for signaling
- Connects to JVB for media streams

### 3. Prosody XMPP Server

**Purpose**: Signaling server for WebRTC

**Features**:
- XMPP/BOSH/WebSocket support
- Multi-domain configuration
- JWT authentication module
- MUC (Multi-User Chat) for conferences

**Ports**:
- 5222: XMPP client connections
- 5269: XMPP server-to-server
- 5347: XMPP component protocol
- 5280: BOSH/WebSocket (internal)

### 4. Jicofo (JItsi COnference FOcus)

**Purpose**: Conference management and orchestration

**Responsibilities**:
- Manages conference lifecycle
- Participant authorization
- Resource allocation
- Bridge selection for conferences

### 5. JVB (Jitsi Videobridge)

**Purpose**: WebRTC media server

**Features**:
- Selective Forwarding Unit (SFU)
- Audio/Video routing
- Simulcast support
- Recording capabilities

**Network**:
- Uses host networking for media
- UDP port 10000 for media streams
- TCP port 4443 as fallback

### 6. Keycloak Authentication

**Purpose**: Enterprise SSO and identity management

**Features**:
- OpenID Connect provider
- JWT token generation
- User management
- Multi-realm support
- Social login integration

**Integration**:
- Provides JWT tokens for Jitsi
- Admin realm for system management
- Jitsi realm for users

### 7. MariaDB Database

**Purpose**: Persistent data storage

**Databases**:
- `keycloak`: Authentication data
- `jitsi`: Meeting history and configuration
- `etherpad`: Document storage

**Configuration**:
- Automated backups
- Optimization via cron jobs
- Connection pooling

### 8. Valkey Cache

**Purpose**: High-performance caching layer

**Usage**:
- Session storage
- Temporary data
- Rate limiting counters
- Real-time metrics

**Features**:
- Redis-compatible
- Persistence enabled
- Memory optimization

## Monitoring Stack

### Prometheus
- **Purpose**: Metrics collection
- **Targets**: All Jitsi services
- **Storage**: Time-series data
- **Port**: 9090 (internal)

### Grafana
- **Purpose**: Visualization and dashboards
- **Instances**:
  - Authenticated (port 3000): Full system metrics
  - Public (port 3002): Anonymous statistics
- **Dashboards**: System, containers, meetings

### Jaeger
- **Purpose**: Distributed tracing
- **Features**: Request flow analysis
- **Port**: 16686 (internal)

### Uptime Kuma
- **Purpose**: Service health monitoring
- **Features**: HTTP checks, notifications
- **Port**: 3001 (internal)

## Network Architecture

### Docker Network
- **Name**: jitsi
- **Type**: Bridge network
- **IP Range**: 172.17.0.0/16 (default)

### Service Communication
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Frontend  │────►│   Backend   │────►│  Database   │
│  (Public)   │     │ (Internal)  │     │ (Internal)  │
└─────────────┘     └─────────────┘     └─────────────┘
     HTTPS              HTTP               MySQL
   Port 443          Port 8000          Port 3306
```

### Security Zones

1. **Public Zone**
   - Nginx (ports 80, 443)
   - JVB media (port 10000)
   - XMPP (ports 5222, 5269, 5347)

2. **Internal Zone**
   - All backend services
   - Database connections
   - Cache operations

3. **Management Zone**
   - SSH access
   - Monitoring interfaces
   - Admin consoles

## Data Flow

### Meeting Creation Flow
```
User → Nginx → Jitsi Web → Keycloak (Auth) → JWT Token
                ↓
         Prosody (XMPP) ← Jicofo (Authorize)
                ↓
              JVB (Media streams)
```

### Authentication Flow
```
1. User accesses Jitsi Meet
2. Redirect to Keycloak login
3. User authenticates
4. Keycloak issues JWT token
5. Token validated by Prosody
6. User joins conference
```

### Media Flow
```
Participant A ─┐
               ├─► JVB ─► Participant C
Participant B ─┘
```

## Scalability Considerations

### Horizontal Scaling

**JVB Scaling**:
- Multiple JVB instances supported
- Load distributed by Jicofo
- Geographic distribution possible

**Web Server Scaling**:
- Stateless design
- Can run multiple instances
- Load balanced by Nginx

### Vertical Scaling

**Resource Allocation**:
- JVB: Increase CPU/RAM for more participants
- Prosody: More RAM for more rooms
- Database: SSD storage recommended

### Performance Limits

| Component | Metric | Limit |
|-----------|--------|-------|
| JVB | Participants per bridge | ~500 |
| Prosody | Concurrent rooms | ~1000 |
| Jicofo | Conferences managed | ~500 |
| System | Total participants | ~2000 |

*Note: Limits depend on hardware specifications*

## Backup and Recovery

### Backup Strategy

```
/opt/jitsi/
├── rootfs/
│   ├── config/     ← Configuration backup
│   ├── data/       ← Application data backup
│   └── db/         ← Database backup
└── .env            ← Environment backup
```

### Recovery Process

1. **Configuration Recovery**
   - Restore `/opt/jitsi/.env`
   - Restore SSL certificates

2. **Data Recovery**
   - Restore database dumps
   - Restore application data

3. **Service Recovery**
   - Redeploy containers
   - Verify configurations

## Security Architecture

### Defense in Depth

1. **Network Layer**
   - Firewall rules
   - Rate limiting
   - DDoS protection

2. **Application Layer**
   - JWT authentication
   - HTTPS everywhere
   - Security headers

3. **Data Layer**
   - Encrypted storage
   - Secure passwords
   - Regular backups

### Authentication Chain

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  User    │───►│  Nginx   │───►│ Keycloak │───►│  Jitsi   │
│          │◄───│          │◄───│          │◄───│          │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
   HTTPS          Proxy          JWT Token       Authorized
```

## Maintenance Architecture

### Automated Tasks

```
Cron Jobs
├── Hourly
│   └── Room cleanup
├── Daily
│   ├── Database optimization
│   ├── Log cleanup
│   ├── Backups
│   └── Cache optimization
├── Weekly
│   ├── Container updates
│   └── Metrics cleanup
└── Every 5 min
    └── Health checks
```

### Helper Scripts

| Script | Purpose | Schedule |
|--------|---------|----------|
| `jitsi-room-cleanup` | Remove old rooms | Hourly |
| `jitsi-db-optimize` | Optimize databases | Daily |
| `jitsi-health-check` | Monitor services | 5 minutes |
| `jitsi-backup-daily` | Create backups | Daily/Weekly |
| `jitsi-diagnose` | Troubleshooting | On-demand |

## Development Considerations

### API Endpoints

- `/api/` - REST API
- `/colibri/stats` - JVB statistics
- `/metrics` - Prometheus metrics
- `/health` - Health checks

### Extension Points

1. **Custom Branding**
   - Modify web interface
   - Update logos/colors

2. **Plugin Development**
   - Prosody modules
   - Web UI plugins

3. **Integration Options**
   - Webhook notifications
   - External authentication
   - Custom analytics

## Next Steps

- [API Reference](api.md) - Detailed API documentation
- [Troubleshooting](troubleshooting.md) - Common issues
- [Configuration](configuration.md) - Customization options