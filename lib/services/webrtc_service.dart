import 'dart:async';
import 'dart:math';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hamrochat/services/socket_service.dart';
import 'package:hamrochat/models/user_model.dart';
import 'package:hamrochat/models/call_history_model.dart';
import 'package:hamrochat/repositories/call_history_repository.dart';
import 'package:permission_handler/permission_handler.dart';

enum CallType { audio, video }

enum CallState { idle, calling, ringing, connected, ended, failed }

class WebRTCService {
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  final SocketService _socketService = SocketService();
  final CallHistoryRepository _callHistoryRepository = CallHistoryRepository();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  CallState _callState = CallState.idle;
  CallType? _currentCallType;
  String? _currentCallId;
  String? _otherUserId;
  UserModel? _otherUser;

  // Stream controllers for UI updates
  final StreamController<CallState> _callStateController =
      StreamController<CallState>.broadcast();
  final StreamController<MediaStream?> _localStreamController =
      StreamController<MediaStream?>.broadcast();
  final StreamController<MediaStream?> _remoteStreamController =
      StreamController<MediaStream?>.broadcast();
  final StreamController<String> _callErrorController =
      StreamController<String>.broadcast();

  // Getters
  CallState get callState => _callState;
  CallType? get currentCallType => _currentCallType;
  String? get currentCallId => _currentCallId;
  String? get otherUserId => _otherUserId;
  UserModel? get otherUser => _otherUser;

  // Streams
  Stream<CallState> get callStateStream => _callStateController.stream;
  Stream<MediaStream?> get localStreamStream => _localStreamController.stream;
  Stream<MediaStream?> get remoteStreamStream => _remoteStreamController.stream;
  Stream<String> get callErrorStream => _callErrorController.stream;

  // Initialize WebRTC
  Future<void> initialize() async {
    await _socketService.initialize();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _socketService.on(
        'call-offer', (data) => _handleCallOffer(data as Map<String, dynamic>));
    _socketService.on('call-answer',
        (data) => _handleCallAnswer(data as Map<String, dynamic>));
    _socketService.on('call-ice-candidate',
        (data) => _handleIceCandidate(data as Map<String, dynamic>));
    _socketService.on(
        'call-end', (data) => _handleCallEnd(data as Map<String, dynamic>));
    _socketService.on('call-reject',
        (data) => _handleCallReject(data as Map<String, dynamic>));
  }

  // Start a call
  Future<void> startCall(
      String otherUserId, UserModel otherUser, CallType callType,
      {UserModel? currentUser}) async {
    try {
      _otherUserId = otherUserId;
      _otherUser = otherUser;
      _currentCallType = callType;
      _currentCallId = _generateCallId();

      _updateCallState(CallState.calling);

      // Save call history if current user is provided
      if (currentUser != null) {
        await _saveCallHistory(
          callerId: currentUser.uid,
          receiverId: otherUserId,
          callerName: currentUser.displayName,
          receiverName: otherUser.displayName,
          callerPhotoURL: currentUser.photoURL,
          receiverPhotoURL: otherUser.photoURL,
          callType: callType,
          callStatus: CallStatus.ongoing,
          isIncoming: false,
        );
      }

      // Request permissions
      await _requestPermissions(callType);

      // Get local media stream
      await _getLocalStream(callType);

      // Create peer connection
      await _createPeerConnection();

      // Send call offer
      await _sendCallOffer(otherUserId);
    } catch (e) {
      _updateCallState(CallState.failed);
      _handleError('Failed to start call: $e');
      rethrow;
    }
  }

  // Answer an incoming call
  Future<void> answerCall() async {
    try {
      if (_currentCallType == null) return;

      _updateCallState(CallState.ringing);

      // Request permissions
      await _requestPermissions(_currentCallType!);

      // Get local media stream
      await _getLocalStream(_currentCallType!);

      // Create peer connection
      await _createPeerConnection();

      // Send call answer
      await _sendCallAnswer();
    } catch (e) {
      _updateCallState(CallState.failed);
      _handleError('Failed to answer call: $e');
      rethrow;
    }
  }

  // End the current call
  Future<void> endCall() async {
    try {
      if (_currentCallId != null) {
        _socketService.emit('call-end', {
          'callId': _currentCallId,
          'to': _otherUserId,
        });

        // Update call history
        await _callHistoryRepository.updateCallStatus(
          callId: _currentCallId!,
          callStatus: CallStatus.answered,
          endTime: DateTime.now(),
        );
      }

      await _cleanup();
      _updateCallState(CallState.ended);
    } catch (e) {
      _handleError('Failed to end call: $e');
    }
  }

  // Reject an incoming call
  Future<void> rejectCall() async {
    try {
      if (_currentCallId != null) {
        _socketService.emit('call-reject', {
          'callId': _currentCallId,
          'to': _otherUserId,
        });

        // Update call history
        await _callHistoryRepository.updateCallStatus(
          callId: _currentCallId!,
          callStatus: CallStatus.rejected,
          endTime: DateTime.now(),
        );
      }

      await _cleanup();
      _updateCallState(CallState.idle);
    } catch (e) {
      _handleError('Failed to reject call: $e');
    }
  }

  // Toggle camera (for video calls)
  Future<void> toggleCamera() async {
    if (_localStream != null && _currentCallType == CallType.video) {
      final videoTrack = _localStream!.getVideoTracks().first;
      videoTrack.enabled = !videoTrack.enabled;
    }
  }

  // Toggle microphone
  Future<void> toggleMicrophone() async {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks().first;
      audioTrack.enabled = !audioTrack.enabled;
    }
  }

  // Switch camera (front/back)
  Future<void> switchCamera() async {
    if (_localStream != null && _currentCallType == CallType.video) {
      await Helper.switchCamera(_localStream!.getVideoTracks().first);
    }
  }

  // Private methods
  Future<void> _requestPermissions(CallType callType) async {
    try {
      // Request microphone permission for all calls
      final microphoneStatus = await Permission.microphone.request();
      if (microphoneStatus != PermissionStatus.granted) {
        throw Exception('Microphone permission is required for calls');
      }

      // Request camera permission for video calls
      if (callType == CallType.video) {
        final cameraStatus = await Permission.camera.request();
        if (cameraStatus != PermissionStatus.granted) {
          throw Exception('Camera permission is required for video calls');
        }
      }
    } catch (e) {
      _handleError('Permission request failed: $e');
      rethrow;
    }
  }

  Future<void> _getLocalStream(CallType callType) async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': callType == CallType.video
          ? {
              'mandatory': {
                'minWidth': '640',
                'minHeight': '480',
                'minFrameRate': '30',
              },
              'facingMode': 'user',
              'optional': [],
            }
          : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localStreamController.add(_localStream);
  }

  Future<void> _createPeerConnection() async {
    final configuration = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    //  Add local tracks to peer connection
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }

//  Handle remote tracks (Unified Plan replaces onAddStream with onTrack)
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _remoteStreamController.add(_remoteStream!);
        _updateCallState(CallState.connected);
      }
    };

    // Handle ICE candidates
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _socketService.emit('call-ice-candidate', {
        'callId': _currentCallId,
        'to': _otherUserId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };
  }

  Future<void> _sendCallOffer(String toUserId) async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    _socketService.emit('call-offer', {
      'callId': _currentCallId,
      'to': toUserId,
      'type': _currentCallType!.index,
      'offer': {
        'type': offer.type,
        'sdp': offer.sdp,
      },
    });
  }

  Future<void> _sendCallAnswer() async {
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    _socketService.emit('call-answer', {
      'callId': _currentCallId,
      'to': _otherUserId,
      'answer': {
        'type': answer.type,
        'sdp': answer.sdp,
      },
    });
  }

  Future<void> _handleCallOffer(Map<String, dynamic> data) async {
    try {
      _currentCallId = data['callId'];
      _otherUserId = data['from'];
      _currentCallType = CallType.values[data['type']];

      _updateCallState(CallState.ringing);

      // Create peer connection
      await _createPeerConnection();

      // Set remote description
      final offer = RTCSessionDescription(
        data['offer']['sdp'],
        data['offer']['type'],
      );
      await _peerConnection!.setRemoteDescription(offer);
    } catch (e) {
      _handleError('Failed to handle call offer: $e');
    }
  }

  Future<void> _handleCallAnswer(Map<String, dynamic> data) async {
    try {
      final answer = RTCSessionDescription(
        data['answer']['sdp'],
        data['answer']['type'],
      );
      await _peerConnection!.setRemoteDescription(answer);
    } catch (e) {
      _handleError('Failed to handle call answer: $e');
    }
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    try {
      final candidate = RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      );
      await _peerConnection!.addCandidate(candidate);
    } catch (e) {
      _handleError('Failed to handle ICE candidate: $e');
    }
  }

  Future<void> _handleCallEnd(Map<String, dynamic> data) async {
    await _cleanup();
    _updateCallState(CallState.ended);
  }

  Future<void> _handleCallReject(Map<String, dynamic> data) async {
    await _cleanup();
    _updateCallState(CallState.ended);
  }

  void _handleError(String error) {
    _callErrorController.add(error);
    _updateCallState(CallState.failed);
  }

  void _updateCallState(CallState state) {
    _callState = state;
    _callStateController.add(state);
  }

  String _generateCallId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  Future<void> _cleanup() async {
    if (_localStream != null) {
      await _localStream!.dispose();
      _localStream = null;
    }
    if (_remoteStream != null) {
      await _remoteStream!.dispose();
      _remoteStream = null;
    }
    if (_peerConnection != null) {
      await _peerConnection!.close();
      _peerConnection = null;
    }
  }

  // Save call history
  Future<void> _saveCallHistory({
    required String callerId,
    required String receiverId,
    required String callerName,
    required String receiverName,
    String? callerPhotoURL,
    String? receiverPhotoURL,
    required CallType callType,
    required CallStatus callStatus,
    required bool isIncoming,
  }) async {
    try {
      await _callHistoryRepository.saveCallHistory(
        callId: _currentCallId ?? _generateCallId(),
        callerId: callerId,
        receiverId: receiverId,
        callerName: callerName,
        receiverName: receiverName,
        callerPhotoURL: callerPhotoURL,
        receiverPhotoURL: receiverPhotoURL,
        callType: callType,
        callStatus: callStatus,
        startTime: DateTime.now(),
        isIncoming: isIncoming,
      );
    } catch (e) {
      print('Failed to save call history: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _cleanup();
    _callStateController.close();
    _localStreamController.close();
    _remoteStreamController.close();
    _callErrorController.close();
  }
}
