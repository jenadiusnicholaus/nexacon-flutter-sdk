import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'exceptions.dart';

/// WebRTC Service - Manages peer connections and media streams
class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final List<RTCIceCandidate> _pendingIceCandidates = [];
  bool _hasRemoteDescription = false;
  bool _iceRestartAttempted = false;

  // Call controls
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;

  // Call duration
  DateTime? _callStartTime;
  Timer? _durationTimer;
  Duration get callDuration => _callStartTime != null
      ? DateTime.now().difference(_callStartTime!)
      : Duration.zero;

  // STUN fallbacks (always present for NAT traversal)
  static final List<Map<String, dynamic>> _stunFallbacks = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:nxservice.quantumvision-tech.com:3478'},
  ];

  final Function(MediaStream)? onLocalStream;
  final Function(MediaStream)? onRemoteStream;
  final Function(Map<String, dynamic>)? onIceCandidate;
  final Function(String)? onCallEnded;

  WebRTCService({
    this.onLocalStream,
    this.onRemoteStream,
    this.onIceCandidate,
    this.onCallEnded,
  });

  /// Initialize peer connection with ICE servers
  Future<void> initializePeerConnection(
    List<Map<String, dynamic>> iceServers,
  ) async {
    // Merge STUN fallbacks with provided servers
    final merged = [..._stunFallbacks];
    for (final server in iceServers) {
      if (!merged.any((m) => m['urls'] == server['urls'])) {
        merged.add(server);
      }
    }

    final configuration = {
      'iceServers': merged,
      'sdpSemantics': 'unified-plan',
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onIceCandidate = (candidate) {
      onIceCandidate?.call({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    _peerConnection!.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        _iceRestartAttempted = false;
        _startDurationTimer();
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        _tryIceRestart();
      }
    };

    _peerConnection!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _iceRestartAttempted = false;
        _startDurationTimer();
      }
    };

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        onRemoteStream?.call(_remoteStream!);
      }
    };
  }

  /// Get user media (audio/video)
  Future<MediaStream> getUserMedia({
    bool audio = true,
    bool video = true,
  }) async {
    final constraints = {
      'audio': audio,
      'video': video
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
            }
          : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    onLocalStream?.call(_localStream!);
    return _localStream!;
  }

  /// Add local stream to peer connection
  Future<void> addLocalStream() async {
    if (_localStream != null && _peerConnection != null) {
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
    }
  }

  /// Create offer (caller)
  Future<RTCSessionDescription> createOffer() async {
    if (_peerConnection == null) {
      throw APIException('Peer connection not initialized');
    }

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  /// Create answer (callee)
  Future<RTCSessionDescription> createAnswer() async {
    if (_peerConnection == null) {
      throw APIException('Peer connection not initialized');
    }

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    return answer;
  }

  /// Set remote description
  Future<void> setRemoteDescription(
    Map<String, dynamic> description,
  ) async {
    if (_peerConnection == null) {
      throw APIException('Peer connection not initialized');
    }

    final sdp = RTCSessionDescription(
      description['sdp'],
      description['type'],
    );

    await _peerConnection!.setRemoteDescription(sdp);
    _hasRemoteDescription = true;

    // Process pending ICE candidates
    await _drainPendingCandidates();
  }

  /// Add ICE candidate (with buffering)
  Future<void> addIceCandidate(Map<String, dynamic> candidate) async {
    if (_peerConnection == null) {
      throw APIException('Peer connection not initialized');
    }

    final rtcCandidate = RTCIceCandidate(
      candidate['candidate'],
      candidate['sdpMid'],
      candidate['sdpMLineIndex'],
    );

    if (!_hasRemoteDescription) {
      _pendingIceCandidates.add(rtcCandidate);
      return;
    }

    await _peerConnection!.addCandidate(rtcCandidate);
  }

  /// Drain pending ICE candidates after remote description is set
  Future<void> _drainPendingCandidates() async {
    if (_pendingIceCandidates.isEmpty) return;
    for (final candidate in _pendingIceCandidates) {
      try {
        await _peerConnection?.addCandidate(candidate);
      } catch (e) {
        print('Error adding buffered ICE candidate: $e');
      }
    }
    _pendingIceCandidates.clear();
  }

  /// Toggle audio track
  void toggleAudio(bool enabled) {
    if (_localStream != null) {
      _isMuted = !enabled;
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = enabled;
      });
    }
  }

  /// Toggle video track
  void toggleVideo(bool enabled) {
    if (_localStream != null) {
      _localStream!.getVideoTracks().forEach((track) {
        track.enabled = enabled;
      });
    }
  }

  /// Toggle speaker
  Future<void> toggleSpeaker(bool enabled) async {
    _isSpeakerOn = enabled;
    try {
      await Helper.setSpeakerphoneOn(enabled);
    } catch (e) {
      print('Error setting speakerphone: $e');
    }
  }

  /// Switch camera
  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTrack = _localStream!
          .getVideoTracks()
          .firstWhere((track) => track.kind == 'video');
      await Helper.switchCamera(videoTrack);
    }
  }

  /// End call and cleanup
  Future<void> endCall() async {
    _stopDurationTimer();

    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) => track.stop());
      await _localStream!.dispose();
      _localStream = null;
    }

    if (_peerConnection != null) {
      await _peerConnection!.close();
      _peerConnection = null;
    }

    _remoteStream = null;
    _hasRemoteDescription = false;
    _pendingIceCandidates.clear();
    _iceRestartAttempted = false;
    _isMuted = false;
    _isSpeakerOn = false;
  }

  /// Start duration timer
  void _startDurationTimer() {
    if (_durationTimer != null) return;
    _callStartTime = DateTime.now();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {});
  }

  /// Stop duration timer
  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _callStartTime = null;
  }

  /// Try ICE restart on connection failure
  Future<void> _tryIceRestart() async {
    if (_peerConnection == null || _iceRestartAttempted) return;
    _iceRestartAttempted = true;

    try {
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false,
        'iceRestart': true,
      });
      await _peerConnection!.setLocalDescription(offer);
      // Signaling service will send the offer
      onIceCandidate?.call({
        'sdp': offer.sdp,
        'type': offer.type,
        'iceRestart': true,
      });

      // Give ICE restart 15 seconds
      await Future.delayed(const Duration(seconds: 15));
      if (_peerConnection != null &&
          iceConnectionState !=
              RTCIceConnectionState.RTCIceConnectionStateConnected) {
        onCallEnded?.call('ICE restart timed out');
      }
    } catch (e) {
      print('ICE restart error: $e');
      onCallEnded?.call('ICE restart failed');
    }
  }

  /// Get current peer connection state
  RTCPeerConnectionState? get peerConnectionState =>
      _peerConnection?.connectionState;

  /// Get current ICE connection state
  RTCIceConnectionState? get iceConnectionState =>
      _peerConnection?.iceConnectionState;

  /// Check if call is active
  bool get isCallActive => _peerConnection != null;
}
