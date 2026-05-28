# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
