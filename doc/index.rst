Nexacon Flutter SDK Documentation
===================================

Welcome to the official documentation for the Nexacon Flutter SDK. This SDK provides a comprehensive solution for integrating peer-to-peer audio and video calling into Flutter applications with minimal setup.

.. toctree::
   :maxdepth: 2
   :caption: Getting Started:

   installation
   quickstart

.. toctree::
   :maxdepth: 2
   :caption: Services:

   messaging
   calls
   devices
   rooms
   presence

.. toctree::
   :maxdepth: 2
   :caption: API Reference:

   api

Overview
--------

The Nexacon Flutter SDK enables developers to add P2P calling capabilities to their Flutter applications through a simple, plug-and-play interface. The SDK handles all complex operations internally:

* **NX Signaling**: Automatic WebSocket connection with reconnection logic
* **WebRTC**: Peer connection management with ICE negotiation
* **Call Management**: Complete call lifecycle handling
* **Platform Support**: iOS, Android, Web, and Desktop
* **Global XMPP Connection**: Shared connection for calls and real-time messaging
* **Automatic Call Analytics**: Records call events on every call end

Features
--------

* NX Token Management
* P2P Audio and Video Calling
* Real-time Messaging with MessagingManager
* Automatic Reconnection (ICE restart)
* ICE Candidate Buffering
* Call Controls (mute, speaker, camera switch)
* Duration Tracking
* Call Statistics (bitrate, packet loss, frame metrics)
* Quality Settings (resolution, FPS, bitrate)
* Call History with filtering
* Cross-platform Support

Services
--------

The SDK provides the following services:

* **Messaging**: Send and receive messages, manage contacts
* **MessagingManager**: Real-time chat via global XMPP connection
* **Calls**: Initiate and manage 1:1 and group calls
* **CallManager**: P2P calling with automatic signaling and WebRTC
* **XmppManager**: Global XMPP connection management
* **Devices**: Register and manage devices for push notifications
* **Rooms**: Create and manage group chat rooms
* **Presence**: Check user online status and last seen
