# WebRTC P2P Voice Call — Client Integration Reference

> **Base URL:** `https://nxservice.quantumvision-tech.com`  
> **All API requests require:** `X-API-Key` + `X-Secret-Key` headers (except Login/Register)

---

## Authentication Headers

| Header | Description |
|--------|-------------|
| `X-API-Key` | Your platform API key (different per client) |
| `X-Secret-Key` | Your platform secret key |
| `X-NX-Token` | User XMPP token (obtained from nxm-token API) |
| `Authorization: Bearer <token>` | User JWT (obtained from login API) |

---

## 1. Auth APIs

### Login
```
POST /api/v1.0/nexacon-auth/login/
Headers: X-API-Key, X-Secret-Key
Body:
{
  "username": "+255XXXXXXXXX",
  "password": "user_password"
}

Response:
{
  "access": "<jwt_access_token>",
  "refresh": "<jwt_refresh_token>",
  "nxsm_token": "<xmpp_token>",
  "nxid": "<user_id>",
  "nxws": "wss://nxservice.quantumvision-tech.com/nx-websocket/"
}
```

### Register
```
POST /api/v1.0/nexacon-auth/register/
Headers: X-API-Key, X-Secret-Key
Body:
{
  "username": "+255XXXXXXXXX",
  "password": "user_password",
  "email": "user@example.com"
}
```

### Refresh JWT Token
```
POST /api/v1.0/nexacon-auth/token/refresh/
Body: { "refresh": "<jwt_refresh_token>" }
Response: { "access": "<new_jwt_access_token>" }
```

---

## 2. XMPP Token APIs

Used to authenticate the user on the ejabberd XMPP server for messaging and call signaling.

### Generate XMPP Token
```
POST /api/v1.0/nexacon-auth/nxm-token/
Headers: X-API-Key, X-Secret-Key
Body:
{
  "username": "+255XXXXXXXXX",
  "host": "nxservice.quantumvision-tech.com"
}

Response:
{
  "token": "<xmpp_jwt>",
  "refresh_token": "<xmpp_refresh_token>",
  "jid": "+255XXXXXXXXX@nxservice.quantumvision-tech.com",
  "username": "+255XXXXXXXXX",
  "host": "nxservice.quantumvision-tech.com",
  "nxws": "wss://nxservice.quantumvision-tech.com/nx-websocket/",
  "expires_in_seconds": 31536000,
  "refresh_expires_in_seconds": 604800
}
```

### Refresh XMPP Token
```
POST /api/v1.0/nexacon-auth/nxm-token/refresh/
Body: { "refresh_token": "<xmpp_refresh_token>" }
Response:
{
  "token": "<new_xmpp_jwt>",
  "jid": "+255XXXXXXXXX@nxservice.quantumvision-tech.com",
  "nxws": "wss://nxservice.quantumvision-tech.com/nx-websocket/",
  "expires_in_seconds": 31536000
}
```

---

## 3. WebRTC / Call APIs

### Get TURN/STUN Credentials ⭐ Required for WebRTC
```
GET /api/v1.0/nx/webrtc/credentials/
Headers: X-API-Key, X-Secret-Key, X-NX-Token

Response:
{
  "status": "success",
  "ice_servers": [
    {
      "urls": "stun:nxservice.quantumvision-tech.com:3478"
    },
    {
      "urls": "turn:nxservice.quantumvision-tech.com:3478?transport=udp",
      "username": "<time_limited_user>",
      "credential": "<hmac_sha1_credential>"
    }
  ],
  "ttl": 86400
}
```
> Credentials are time-limited (24h TTL). Fetch fresh credentials before each call.

---

### Initiate Call (FCM Push + XMPP) ⭐ Required for background calls
```
POST /api/v1.0/nx/webrtc/call/
Headers: X-API-Key, X-Secret-Key, X-NX-Token
Body:
{
  "to": "+255XXXXXXXXX",
  "type": "p2p",
  "room": "call_<timestamp>"
}

Response:
{
  "status": "success",
  "call_id": "<generated_id>",
  "room": "call_<timestamp>",
  "to": "+255XXXXXXXXX",
  "type": "p2p",
  "status": "initiated",
  "fcm_sent": true
}
```
> This sends both an XMPP message AND an FCM push notification to wake the recipient's app.

---

### Register Device for FCM Push ⭐ Required on app startup
```
POST /api/v1.0/nx/register-device/
Headers: X-API-Key, X-Secret-Key, X-NX-Token
Body:
{
  "fcm_token": "<firebase_device_token>",
  "platform": "android",
  "device_name": "Pixel 7"
}

Response:
{
  "status": "success",
  "registered": true,
  "device_id": 42,
  "platform": "android",
  "nxid": "+255XXXXXXXXX",
  "client_id": "your_client_id"
}
```

### Unregister Device (on logout)
```
DELETE /api/v1.0/nx/register-device/
Headers: X-API-Key, X-Secret-Key, X-NX-Token
Body: { "fcm_token": "<firebase_device_token>" }
Response: { "status": "success", "unregistered": true }
```

---

## 4. XMPP Connection (Signaling Channel)

Connect to ejabberd using the XMPP token from step 2.

| Protocol | URL |
|----------|-----|
| WebSocket | `wss://nxservice.quantumvision-tech.com/nx-websocket/` |
| BOSH (HTTP fallback) | `https://nxservice.quantumvision-tech.com/nx-bosh/` |

**Credentials:**
- JID: `+255XXXXXXXXX@nxservice.quantumvision-tech.com`
- Password: XMPP token (`token` field from nxm-token API)

---

## 5. Signaling Message Types (over XMPP)

All messages sent as XMPP `<message type="chat">` stanzas with a JSON body.

| Type | Sender | Payload |
|------|--------|---------|
| `call_invitation` | Caller → Callee | `{type, roomId, callType, fromJid, fromName, timestamp}` |
| `call_response` | Callee → Caller | `{type, accepted: true/false, roomId, timestamp}` |
| `call_end` | Either → Either | `{type, roomId, timestamp}` |
| `webrtc_offer` | Caller → Callee | `{type, sdp, sdp_type: "offer", roomId}` |
| `webrtc_answer` | Callee → Caller | `{type, sdp, sdp_type: "answer", roomId}` |
| `webrtc_ice_candidate` | Both → Both | `{type, candidate, sdpMid, sdpMLineIndex, roomId}` |

---

## 6. Full Call Flow

```
CALLER                              CALLEE
  │                                   │
  │─── POST /nx/webrtc/call/ ────────►│ (FCM wakes app if background)
  │─── XMPP: call_invitation ────────►│ (XMPP delivers if app active)
  │                                   │
  │                             [show incoming call UI]
  │                                   │
  │◄── XMPP: call_response ───────────│ {accepted: true}
  │                                   │
  │  [GET /nx/webrtc/credentials/]    │  [GET /nx/webrtc/credentials/]
  │  [createPeerConnection(iceServers)]│  [createPeerConnection(iceServers)]
  │  [getUserMedia()]                 │  [getUserMedia()]
  │                                   │
  │─── XMPP: webrtc_offer ───────────►│
  │                             [setRemoteDescription]
  │                             [createAnswer]
  │◄── XMPP: webrtc_answer ───────────│
  │  [setRemoteDescription]           │
  │                                   │
  │◄══ XMPP: webrtc_ice_candidate ════│ (both directions, buffered)
  │══► XMPP: webrtc_ice_candidate ════│
  │                                   │
  │       [TURN relay connects]       │
  │◄══════════ Audio flows ═══════════│
  │                                   │
  │─── XMPP: call_end ───────────────►│ (either side hangs up)
```

---

## 7. ICE Server Configuration

Build from the `/nx/webrtc/credentials/` response:

```javascript
// JavaScript / Web
const pc = new RTCPeerConnection({
  iceServers: credentials.ice_servers
})
```

```dart
// Flutter / Dart
final pc = await createPeerConnection({
  'iceServers': credentials['ice_servers'],
  'sdpSemantics': 'unified-plan',
});
```

**Always include Google STUN as fallback:**
```json
{ "urls": "stun:stun.l.google.com:19302" }
```

---

## 8. ICE Candidate Buffering (Important)

Candidates may arrive **before** `setRemoteDescription` completes. Buffer them:

```javascript
// Buffer until remote description is set
const pending = []
let hasRemote = false

pc.onicecandidate = (e) => {
  if (e.candidate) sendViaXmpp('webrtc_ice_candidate', e.candidate)
}

async function handleRemoteCandidate(data) {
  if (!hasRemote) {
    pending.push(data)
  } else {
    await pc.addIceCandidate(new RTCIceCandidate(data))
  }
}

async function handleOffer(data) {
  await pc.setRemoteDescription(new RTCSessionDescription(data))
  hasRemote = true
  for (const c of pending) await pc.addIceCandidate(new RTCIceCandidate(c))
  pending.length = 0
  // ... createAnswer, setLocalDescription, send answer
}
```

---

## 9. Flutter Dependencies

```yaml
# pubspec.yaml
flutter_webrtc: ^0.x.x        # WebRTC peer connection
firebase_messaging: ^x.x.x    # FCM push for background calls
flutter_ringtone_player: ^x.x.x
get: ^x.x.x                   # Navigation / state
dio: ^x.x.x                   # HTTP for credentials API
```

**Android Permissions** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
<uses-permission android:name="android.permission.BLUETOOTH"/>
```

---

## 10. Web / JavaScript Dependencies

```json
"strophe.js": "^1.x.x"
```
> WebRTC is a native browser API — no extra package needed.

---

## 11. Server Infrastructure

| Component | Details |
|-----------|---------|
| **XMPP Server** | ejabberd — `nxservice.quantumvision-tech.com` |
| **TURN/STUN Server** | coturn — ports `3478` (UDP/TCP), `5349` (TLS) |
| **Backend** | Django REST Framework |
| **Push Notifications** | Firebase Cloud Messaging V1 API (per-client Firebase project) |

---

## 12. Key Notes for Client Integration

1. **Fetch TURN credentials fresh before every call** — they expire after 24 hours.
2. **Register FCM token on app startup** — required for receiving calls when app is backgrounded.
3. **Use BOSH fallback** if WebSocket fails — connect to `/nx-bosh/` with the same XMPP JWT.
4. **Buffer ICE candidates** until `setRemoteDescription` completes (see section 8).
5. **Standardize on `call_end`** (not `call_ended`) for the hangup signal type on both sides.
6. **XMPP token vs JWT token** — these are different: JWT is for REST APIs, XMPP token is for XMPP connection.
7. **X-API-Key is per-client** — each integrated client gets their own key pair from the Nexacon admin.
