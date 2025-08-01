# API Reference

This document describes the available APIs for integrating with Jitsi Meet Enterprise.

## Overview

Jitsi Meet Enterprise provides several APIs for integration:

1. **REST API** - Conference management
2. **Colibri API** - Statistics and monitoring
3. **XMPP API** - Real-time messaging
4. **IFrame API** - Web embedding
5. **Webhook API** - Event notifications

## Authentication

### JWT Authentication

All API requests require JWT authentication. Tokens are issued by Keycloak.

**Token Format**:
```json
{
  "iss": "your-domain.com",
  "sub": "user@example.com",
  "aud": "jitsi",
  "exp": 1234567890,
  "room": "*",
  "context": {
    "user": {
      "name": "John Doe",
      "email": "user@example.com",
      "avatar": "https://example.com/avatar.jpg"
    }
  }
}
```

**Authorization Header**:
```
Authorization: Bearer <JWT_TOKEN>
```

### Obtaining a Token

```bash
# Via Keycloak REST API
curl -X POST https://auth.your-domain.com/auth/realms/jitsi/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=jitsi-meet" \
  -d "username=user@example.com" \
  -d "password=password" \
  -d "grant_type=password"
```

## REST API

Base URL: `https://api.your-domain.com/`

### Conference Management

#### Create Conference

```http
POST /api/v1/conferences
Content-Type: application/json
Authorization: Bearer <token>

{
  "name": "my-meeting",
  "subject": "Team Standup",
  "startTime": "2025-02-01T10:00:00Z",
  "duration": 3600
}
```

**Response**:
```json
{
  "id": "abc123",
  "name": "my-meeting",
  "url": "https://meet.your-domain.com/my-meeting",
  "jwt": "conference-specific-jwt-token"
}
```

#### Get Conference Info

```http
GET /api/v1/conferences/{id}
Authorization: Bearer <token>
```

**Response**:
```json
{
  "id": "abc123",
  "name": "my-meeting",
  "subject": "Team Standup",
  "participants": 5,
  "duration": 1800,
  "startTime": "2025-02-01T10:00:00Z",
  "active": true
}
```

#### List Active Conferences

```http
GET /api/v1/conferences?active=true
Authorization: Bearer <token>
```

**Response**:
```json
{
  "conferences": [
    {
      "id": "abc123",
      "name": "my-meeting",
      "participants": 5,
      "startTime": "2025-02-01T10:00:00Z"
    }
  ],
  "total": 1
}
```

#### End Conference

```http
DELETE /api/v1/conferences/{id}
Authorization: Bearer <token>
```

**Response**:
```json
{
  "success": true,
  "message": "Conference ended"
}
```

### Participant Management

#### List Participants

```http
GET /api/v1/conferences/{id}/participants
Authorization: Bearer <token>
```

**Response**:
```json
{
  "participants": [
    {
      "id": "participant-1",
      "displayName": "John Doe",
      "email": "john@example.com",
      "joinTime": "2025-02-01T10:05:00Z",
      "role": "moderator"
    }
  ],
  "total": 1
}
```

#### Kick Participant

```http
DELETE /api/v1/conferences/{id}/participants/{participantId}
Authorization: Bearer <token>
```

#### Mute Participant

```http
POST /api/v1/conferences/{id}/participants/{participantId}/mute
Authorization: Bearer <token>

{
  "mediaType": "audio"
}
```

### Recording Management

#### Start Recording

```http
POST /api/v1/conferences/{id}/recording/start
Authorization: Bearer <token>

{
  "mode": "file",
  "format": "mp4"
}
```

#### Stop Recording

```http
POST /api/v1/conferences/{id}/recording/stop
Authorization: Bearer <token>
```

#### List Recordings

```http
GET /api/v1/recordings?conferenceId={id}
Authorization: Bearer <token>
```

## Colibri Statistics API

Base URL: `https://your-domain.com/colibri/stats`

### Get JVB Statistics

```http
GET /colibri/stats
```

**Response**:
```json
{
  "conferences": 10,
  "participants": 50,
  "videostreams": 45,
  "jitter_aggregate": 15,
  "packet_rate_download": 1000,
  "packet_rate_upload": 900,
  "loss_rate_download": 0.01,
  "loss_rate_upload": 0.02,
  "version": "2.1.0",
  "threads": 50,
  "cpu_usage": 0.15,
  "used_memory": 512,
  "total_memory": 2048
}
```

## IFrame API

### Basic Embedding

```html
<div id="meet"></div>
<script src='https://meet.your-domain.com/external_api.js'></script>
<script>
  const domain = 'meet.your-domain.com';
  const options = {
    roomName: 'MyMeetingRoom',
    width: 700,
    height: 700,
    parentNode: document.querySelector('#meet'),
    jwt: 'your-jwt-token',
    configOverwrite: {
      startWithAudioMuted: true,
      startWithVideoMuted: true
    },
    interfaceConfigOverwrite: {
      TOOLBAR_BUTTONS: [
        'microphone', 'camera', 'closedcaptions', 'desktop', 
        'fullscreen', 'fodeviceselection', 'hangup', 'profile', 
        'info', 'chat', 'recording', 'settings', 'raisehand',
        'videoquality', 'filmstrip', 'stats', 'shortcuts',
        'tileview', 'videobackgroundblur', 'download', 'help'
      ]
    }
  };
  
  const api = new JitsiMeetExternalAPI(domain, options);
</script>
```

### IFrame API Events

```javascript
// Participant joined
api.addEventListener('participantJoined', (event) => {
  console.log('Participant joined:', event.id);
});

// Participant left
api.addEventListener('participantLeft', (event) => {
  console.log('Participant left:', event.id);
});

// Conference joined
api.addEventListener('videoConferenceJoined', (event) => {
  console.log('Conference joined:', event.roomName);
});

// Conference left
api.addEventListener('videoConferenceLeft', (event) => {
  console.log('Conference left:', event.roomName);
});

// Recording status
api.addEventListener('recordingStatusChanged', (event) => {
  console.log('Recording:', event.on ? 'started' : 'stopped');
});
```

### IFrame API Commands

```javascript
// Mute/unmute audio
api.executeCommand('toggleAudio');

// Mute/unmute video
api.executeCommand('toggleVideo');

// Toggle fullscreen
api.executeCommand('toggleFullscreen');

// Toggle tile view
api.executeCommand('toggleTileView');

// Start recording
api.executeCommand('startRecording', {
  mode: 'file',
  youtubeBroadcastID: 'optional-youtube-id'
});

// Stop recording
api.executeCommand('stopRecording');

// Set display name
api.executeCommand('displayName', 'New Name');

// Send chat message
api.executeCommand('sendChatMessage', 'Hello everyone!');

// Leave conference
api.executeCommand('hangup');
```

## Webhook API

### Configuration

Configure webhooks in `/opt/jitsi/.env`:
```bash
JITSI_WEBHOOK_URL="https://your-webhook-endpoint.com/webhook"
JITSI_WEBHOOK_SECRET="your-webhook-secret"
```

### Event Types

#### Conference Created
```json
{
  "event": "conference.created",
  "timestamp": "2025-02-01T10:00:00Z",
  "data": {
    "conferenceId": "abc123",
    "name": "my-meeting",
    "creator": "user@example.com"
  }
}
```

#### Participant Joined
```json
{
  "event": "participant.joined",
  "timestamp": "2025-02-01T10:05:00Z",
  "data": {
    "conferenceId": "abc123",
    "participantId": "xyz789",
    "displayName": "John Doe",
    "email": "john@example.com"
  }
}
```

#### Recording Started
```json
{
  "event": "recording.started",
  "timestamp": "2025-02-01T10:10:00Z",
  "data": {
    "conferenceId": "abc123",
    "recordingId": "rec123",
    "initiator": "user@example.com"
  }
}
```

### Webhook Security

All webhooks include HMAC signature:
```
X-Jitsi-Signature: sha256=<hmac-signature>
```

Verify signature:
```javascript
const crypto = require('crypto');

function verifyWebhook(payload, signature, secret) {
  const hmac = crypto.createHmac('sha256', secret);
  hmac.update(JSON.stringify(payload));
  const calculatedSignature = 'sha256=' + hmac.digest('hex');
  
  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(calculatedSignature)
  );
}
```

## Monitoring APIs

### Prometheus Metrics

```http
GET https://metrics.your-domain.com/metrics
```

**Sample Response**:
```
# HELP jitsi_conferences_total Total number of conferences
# TYPE jitsi_conferences_total counter
jitsi_conferences_total 150

# HELP jitsi_participants_total Total number of participants
# TYPE jitsi_participants_total gauge
jitsi_participants_total 45

# HELP jitsi_jvb_packet_rate_download Download packet rate
# TYPE jitsi_jvb_packet_rate_download gauge
jitsi_jvb_packet_rate_download 1250
```

### Health Check Endpoints

#### Main Application Health
```http
GET https://your-domain.com/healthz
```

#### Service-Specific Health
```http
GET https://api.your-domain.com/health
GET https://auth.your-domain.com/health
GET https://grafana.your-domain.com/api/health
```

**Response Format**:
```json
{
  "status": "healthy",
  "timestamp": "2025-02-01T10:00:00Z",
  "services": {
    "database": "healthy",
    "cache": "healthy",
    "xmpp": "healthy"
  }
}
```

## Rate Limiting

API rate limits:
- Anonymous: 5 requests/second
- Authenticated: 20 requests/second
- Burst: 50 requests

Rate limit headers:
```
X-RateLimit-Limit: 20
X-RateLimit-Remaining: 15
X-RateLimit-Reset: 1234567890
```

## Error Responses

Standard error format:
```json
{
  "error": {
    "code": "CONFERENCE_NOT_FOUND",
    "message": "Conference with ID 'abc123' not found",
    "timestamp": "2025-02-01T10:00:00Z",
    "requestId": "req-123456"
  }
}
```

Common error codes:
- `UNAUTHORIZED` - Invalid or missing JWT
- `FORBIDDEN` - Insufficient permissions
- `NOT_FOUND` - Resource not found
- `RATE_LIMITED` - Too many requests
- `INTERNAL_ERROR` - Server error

## SDK and Libraries

### JavaScript SDK
```bash
npm install @jitsi/meet-sdk
```

```javascript
const JitsiMeetSDK = require('@jitsi/meet-sdk');

const client = new JitsiMeetSDK({
  domain: 'meet.your-domain.com',
  jwt: 'your-jwt-token'
});

// Create conference
const conference = await client.createConference({
  name: 'my-meeting',
  subject: 'Team Meeting'
});
```

### Python SDK
```bash
pip install jitsi-meet-sdk
```

```python
from jitsi_meet import JitsiMeetClient

client = JitsiMeetClient(
    domain='meet.your-domain.com',
    jwt='your-jwt-token'
)

# Create conference
conference = client.create_conference(
    name='my-meeting',
    subject='Team Meeting'
)
```

## Best Practices

1. **Authentication**
   - Always use JWT tokens
   - Set appropriate expiration times
   - Rotate secrets regularly

2. **Rate Limiting**
   - Implement exponential backoff
   - Cache responses when possible
   - Use webhooks for real-time updates

3. **Error Handling**
   - Always check response status
   - Handle network timeouts
   - Log errors for debugging

4. **Security**
   - Use HTTPS for all requests
   - Validate webhook signatures
   - Sanitize user inputs

## Next Steps

- [Troubleshooting](troubleshooting.md) - Debug common issues
- [Configuration](configuration.md) - API configuration
- [Architecture](architecture.md) - System design