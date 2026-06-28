# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.7] - 2026-06-28

### Fixed

- `acceptFromNotification(callerJid:)` → `acceptFromNotification(callerNxId:)` to match renamed `prepareIncomingCall(callerNxId:)` parameter

## [1.2.6] - 2026-06-28

### Changed

- Replaced all internal `JID`/`XMPP` terminology with `NxID`/`NX` across comments, logs, and variable names
- `fromJid` → `fromNxId` in signaling message payloads
- `_myJid`/`_peerJid` → `_myNxId`/`_peerNxId` in CallManager
- `_normalizePeerJid()` → `_resolveNxId()` in CallManager
- `prepareIncomingCall(callerJid:)` → `prepareIncomingCall(callerNxId:)`
- `refreshXMPPToken()` → `refreshNxToken()` in Auth service

## [1.2.5] - 2026-06-28

### Fixed

- **Critical**: WebRTC offer never reached consultant after `callResponse` due to wrong `_peerJid`
- `XmppManager` now injects `message.from` (actual sender XMPP JID) into all signaling messages
- `CallManager._handleCallResponse()` now updates `_peerJid` to the real sender JID from the XMPP envelope, ensuring `webrtcOffer` and ICE candidates are routed correctly

## [1.2.4] - 2026-06-28

### Added

- `_normalizePeerJid()` in CallManager to correctly format XMPP JIDs by stripping country code prefix that Nexacon server strips
- Debug logging for signaling messages and JID resolution in CallManager

### Fixed

- Reuse pre-warmed XMPP connection in `startCall()` and `acceptWhenReady()` to avoid duplicate sessions
- XMPP JID mismatch when caller used formatted phone number (+255...) but server stored bare digits

## [1.2.3] - 2026-06-28

### Fixed

- Added missing changelog entries for versions 1.2.0, 1.2.1, and 1.2.2
- Improved pub.dev score by ensuring all versions are documented

## [1.2.2] - 2026-06-28

### Added

- `prepareIncomingCall()` to CallManager for injecting call state from push notification payload
- `acceptFromNotification()` to NexaconSDK for accepting calls using FCM/push data
- Documentation for dual-path incoming call support (XMPP vs FCM)

### Changed

- Updated README with XMPP-first and FCM-first incoming call examples

## [1.2.1] - 2026-06-27

### Added

- `acceptWhenReady()` to NexaconSDK for simplified incoming call handling
- Automatically waits for XMPP call invitation signal before accepting

### Fixed

- Call response timeout when using invalid recipient identifier

## [1.2.0] - 2026-06-27

### Added

- Simplified NexaconSDK API with `startCall()` and `acceptCall()` methods
- Automatic connection management and signaling setup
- Streamlined call initialization for both outgoing and incoming calls

### Changed

- Deprecated manual CallManager initialization in favor of simplified API
- Updated README with simplified quick start guide

## [1.1.5] - 2026-06-25

### Fixed

- Fixed repository URL to match actual GitHub repository
- Fixed issue tracker URL to match actual GitHub repository
- Updated dependencies to latest versions:
  - http: ^1.1.0 → ^1.2.0
  - json_annotation: ^4.8.0 → ^4.12.0
  - flutter_webrtc: ^0.9.48 → ^1.5.2
  - web_socket_client: ^0.1.2 → ^0.2.1
  - flutter_lints: ^3.0.0 → ^6.0.0
  - json_serializable: ^6.7.0 → ^6.14.0
  - mockito: ^5.4.4 → ^5.6.4

## [1.1.4] - 2026-05-28

### Changed

- Renamed internal `_xmppManager` to `_nxManager` throughout codebase
- Updated documentation to remove XMPP references from public API

## [1.1.3] - 2026-05-28

### Added

- FoldStateService for detecting foldable device state changes
- FoldState enum (flat, folded, halfOpen, unknown)
- Android native fold detection reference implementation
- Fold state stream for real-time updates
- Documentation for foldable device support

## [1.1.2] - 2026-05-28

### Added

- Official platform support for Linux, macOS, and Windows
- Platform-specific configuration documentation
- Added platforms section to pubspec.yaml

### Changed

- Updated README with complete platform configuration for all 6 platforms
- Updated Flutter SDK version requirement to >=3.0.0

## [1.1.1] - 2026-05-28

### Changed

- Removed XmppManager from public API exports
- Removed XMPP-specific references from documentation
- Simplified messaging setup (no manual connection needed)
- Updated README to hide implementation details

## [1.1.0] - 2026-05-28

### Added

- Real-time messaging with XMPP
- MessagingManager for instant messaging
- Typing indicators (XEP-0085)
- Read receipts (XEP-0184)
- Delivery receipts support
- Presence management (online/offline status)
- Message history API with filters and pagination
- XmppManager presence stream
- XmppManager delivery receipt stream
- Heartbeat for connection keep-alive
- Automatic reconnection with exponential backoff
- Enhanced documentation for messaging features

### Changed

- Updated README with messaging examples
- Updated package description to include messaging

## [1.0.1] - 2024-05-28

### Added

- Flutter example app with UI for P2P calling
- Interactive example demonstrating CallManager usage
- Exported CallManager, WebRTCService, and SignalingService in main library

## [1.0.0] - 2024-05-28

### Added

- Initial release of Nexacon Flutter SDK
- P2P audio and video calling with WebRTC
- NX signaling with automatic WebSocket connection
- CallManager for plug-and-play call management
- NX token generation and refresh
- Automatic ICE candidate buffering and exchange
- ICE restart on connection failure
- Call controls: mute, speaker toggle, camera switch
- Call duration tracking
- Platform support: iOS, Android, Web, Desktop
- Comprehensive documentation with Read the Docs integration
