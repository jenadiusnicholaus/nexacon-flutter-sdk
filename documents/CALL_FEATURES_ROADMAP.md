# Call Features Implementation Roadmap

## MVP - Completed ✅

### Core P2P Calling
- **CallManager** - Full P2P call orchestration with signaling
- **WebRTCService** - Peer connection management, ICE negotiation
- **Global XmppManager** - Shared XMPP connection for calls + messaging
- **MessagingManager** - Real-time chat via XMPP
- **Automatic call analytics** - Records call events on end
- **Stream exposure** - Local/remote video streams to UI
- **Call duration tracking** - Built-in timer
- **Call controls** - Mute/unmute, speaker toggle, camera switch
- **ICE restart** - Automatic reconnection on failure

### Quality & Statistics (MVP+)
- **Video quality settings** - Resolution (width/height), FPS
- **Bitrate control** - Audio/video bitrate limits
- **Call statistics** - Real-time bitrate, packet loss, frame metrics
- **Stats stream** - Periodic statistics updates via stream

### API Integration
- **Call history** - Fetch past calls with filters
- **Call analytics** - Record call events (ended, failed, declined, missed)
- **WebRTC credentials** - STUN/TURN server credentials

---

## Next Implementation Steps

### 1. Group Calls (SFU Required)

**Backend Requirements:**
- SFU (Selective Forwarding Unit) server for multi-party streams
- Options: Jitsi, Mediasoup, Janus, or custom SFU
- API endpoints needed:
  ```
  POST /nx/sfu/create-room/    # Create SFU room
  POST /nx/sfu/join-room/      # Join SFU room (returns SFU URL)
  POST /nx/sfu/leave-room/     # Leave SFU room
  GET  /nx/sfu/room-info/      # Get room participants
  ```

**SDK Implementation:**
- `GroupCallManager` class extending CallManager
- Multi-stream handling (multiple remote video tracks)
- Participant management (mute/kick controls)
- SFU signaling integration

**Priority:** High (enterprise feature)

---

### 2. Screen Sharing

**Backend:** Not required (client-side WebRTC)

**SDK Implementation:**
- Add to `WebRTCService`:
  ```dart
  Future<MediaStream> getDisplayMedia() async {
    final stream = await navigator.mediaDevices.getDisplayMedia({
      'video': true,
      'audio': false,
    });
    return stream;
  }
  ```
- UI controls for start/stop screen share
- Signaling message type: `screen_share_offer`

**Priority:** Medium (desktop-focused)

---

### 3. Call Recording (Media)

**Backend Requirements:**
- Media storage (S3, GCS, or local)
- Recording API:
  ```
  POST /nx/call-recording/start/  # Start recording
  POST /nx/call-recording/stop/   # Stop recording
  GET  /nx/call-recording/<id>/    # Get recording URL
  ```

**SDK Implementation:**
- MediaRecorder API integration
- Recording controls in CallManager
- Recording state management

**Priority:** Medium (compliance feature)

---

### 4. Remote Participant Controls

**Backend Requirements:**
- Permission system for call controls
- API endpoints:
  ```
  POST /nx/call-controls/mute/     # Mute remote participant
  POST /nx/call-controls/kick/     # Remove participant
  POST /nx/call-controls/raise-hand/  # Hand raise
  ```

**SDK Implementation:**
- Signaling messages for control commands
- Permission checks before sending commands
- UI feedback for control actions

**Priority:** Low (moderation feature)

---

### 5. Enhanced Reconnection Logic

**Backend:** Not required (client-side)

**SDK Implementation:**
- Improve ICE restart in WebRTCService:
  - Multiple retry attempts with exponential backoff
  - Fallback to TURN servers if STUN fails
  - Network change detection (WiFi ↔ cellular)
  - Automatic SDP renegotiation

**Priority:** High (reliability)

---

### 6. Advanced Statistics Dashboard

**Backend:** Optional (for centralized analytics)

**SDK Implementation:**
- Enhanced stats collection:
  - CPU/memory usage
  - Network latency (RTT)
  - Jitter measurement
  - Resolution changes over time
- Export stats to CSV/JSON
- Real-time graphing support

**Priority:** Low (debugging tool)

---

## Backend API Endpoints to Add

### Call History (Already exists at `/nx/call-history/`)
- ✅ Implemented in SDK

### Group Call SFU (New)
```python
# /nx/urls.py additions
path("sfu/create-room/", SFUCreateRoomView.as_view(), name="nx-sfu-create-room"),
path("sfu/join-room/", SFUJoinRoomView.as_view(), name="nx-sfu-join-room"),
path("sfu/leave-room/", SFULeaveRoomView.as_view(), name="nx-sfu-leave-room"),
path("sfu/room-info/", SFURoomInfoView.as_view(), name="nx-sfu-room-info"),
```

### Call Recording (New)
```python
path("call-recording/start/", CallRecordingStartView.as_view(), name="nx-recording-start"),
path("call-recording/stop/", CallRecordingStopView.as_view(), name="nx-recording-stop"),
path("call-recording/<uuid:id>/", CallRecordingDetailView.as_view(), name="nx-recording-detail"),
```

### Call Controls (New)
```python
path("call-controls/mute/", CallControlMuteView.as_view(), name="nx-control-mute"),
path("call-controls/kick/", CallControlKickView.as_view(), name="nx-control-kick"),
path("call-controls/raise-hand/", CallControlRaiseHandView.as_view(), name="nx-control-raise-hand"),
```

---

## Recommended Implementation Order

1. **Enhanced Reconnection Logic** - Improves reliability immediately
2. **Screen Sharing** - Client-side, no backend needed
3. **Group Calls (SFU)** - Major feature, requires infrastructure
4. **Call Recording** - Compliance requirement for many use cases
5. **Remote Controls** - Moderation features
6. **Advanced Statistics** - Debugging/monitoring

---

## Testing Strategy

### Unit Tests
- WebRTCService stats collection
- Quality settings application
- ICE restart logic

### Integration Tests
- End-to-end call with quality changes
- Stats stream verification
- Reconnection simulation

### Manual Testing
- Network switching during call
- Poor network conditions
- Multi-device scenarios

---

## Performance Considerations

### Stats Collection
- Default interval: 2 seconds
- Can be adjusted for debugging (1s) or production (5s)
- CPU impact: minimal (WebRTC stats are lightweight)

### Quality Settings
- Higher resolution = more bandwidth
- Recommended presets:
  - Low: 640x480 @ 15fps, 500kbps
  - Medium: 1280x720 @ 30fps, 1000kbps (default)
  - High: 1920x1080 @ 30fps, 2000kbps

### ICE Restart
- Timeout: 15 seconds
- Single retry attempt (configurable)
- Fallback to end call if restart fails

---

## Documentation Updates Needed

1. **Calls.rst** - Add quality settings, stats, call history
2. **Quick Start** - Add stats collection example
3. **API Reference** - Document new methods
4. **Examples** - Add quality tuning examples
