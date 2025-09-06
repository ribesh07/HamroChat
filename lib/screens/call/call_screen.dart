import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hamrochat/services/webrtc_service.dart';
import 'package:hamrochat/models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CallScreen extends ConsumerStatefulWidget {
  final UserModel otherUser;
  final CallType callType;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.otherUser,
    required this.callType,
    this.isIncoming = false,
  });

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  final WebRTCService _webrtcService = WebRTCService();
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = false;
  RTCVideoRenderer? _localVideoRenderer;
  RTCVideoRenderer? _remoteVideoRenderer;

  @override
  void initState() {
    super.initState();
    _initializeVideoRenderers();
    _initializeCall();
  }

  @override
  void dispose() {
    _localVideoRenderer?.dispose();
    _remoteVideoRenderer?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoRenderers() async {
    if (widget.callType == CallType.video) {
      _localVideoRenderer = RTCVideoRenderer();
      _remoteVideoRenderer = RTCVideoRenderer();
      await _localVideoRenderer!.initialize();
      await _remoteVideoRenderer!.initialize();
    }
  }

  Future<void> _initializeCall() async {
    if (widget.isIncoming) {
      // Handle incoming call
    } else {
      // Start outgoing call
      await _webrtcService.startCall(
        widget.otherUser.uid,
        widget.otherUser,
        widget.callType,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: StreamBuilder<CallState>(
          stream: _webrtcService.callStateStream,
          builder: (context, snapshot) {
            final callState = snapshot.data ?? CallState.idle;

            return Column(
              children: [
                // Top status bar
                _buildStatusBar(callState),

                // Main content area
                Expanded(
                  child: _buildMainContent(callState),
                ),

                // Bottom controls
                _buildControls(callState),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusBar(CallState callState) {
    String statusText;
    Color statusColor;

    switch (callState) {
      case CallState.calling:
        statusText = 'Calling...';
        statusColor = Colors.orange;
        break;
      case CallState.ringing:
        statusText = widget.isIncoming ? 'Incoming call' : 'Ringing...';
        statusColor = Colors.blue;
        break;
      case CallState.connected:
        statusText = 'Connected';
        statusColor = Colors.green;
        break;
      case CallState.ended:
        statusText = 'Call ended';
        statusColor = Colors.grey;
        break;
      case CallState.failed:
        statusText = 'Call failed';
        statusColor = Colors.red;
        break;
      default:
        statusText = '';
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (callState == CallState.connected)
                  Text(
                    '00:00', // TODO: Add call duration timer
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(CallState callState) {
    if (callState == CallState.ended || callState == CallState.failed) {
      return _buildCallEndedContent();
    }

    return Stack(
      children: [
        // Remote video (or placeholder)
        _buildRemoteVideo(),

        // Local video (for video calls)
        if (widget.callType == CallType.video)
          Positioned(
            top: 20,
            right: 20,
            child: _buildLocalVideo(),
          ),

        // User info overlay
        if (callState != CallState.connected ||
            widget.callType == CallType.audio)
          _buildUserInfoOverlay(),
      ],
    );
  }

  Widget _buildRemoteVideo() {
    return StreamBuilder<MediaStream?>(
      stream: _webrtcService.remoteStreamStream,
      builder: (context, snapshot) {
        final remoteStream = snapshot.data;

        if (remoteStream != null &&
            widget.callType == CallType.video &&
            _remoteVideoRenderer != null) {
          _remoteVideoRenderer!.srcObject = remoteStream;
          return RTCVideoView(
            _remoteVideoRenderer!,
            mirror: false,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          );
        }

        // Placeholder for audio calls or when no video
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue[800]!,
                Colors.blue[600]!,
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.person,
              size: 120,
              color: Colors.white70,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocalVideo() {
    return StreamBuilder<MediaStream?>(
      stream: _webrtcService.localStreamStream,
      builder: (context, snapshot) {
        final localStream = snapshot.data;

        if (localStream != null &&
            widget.callType == CallType.video &&
            _localVideoRenderer != null) {
          _localVideoRenderer!.srcObject = localStream;
          return Container(
            width: 100,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: RTCVideoView(
                _localVideoRenderer!,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildUserInfoOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 80,
              backgroundImage: widget.otherUser.photoURL != null
                  ? CachedNetworkImageProvider(widget.otherUser.photoURL!)
                  : null,
              child: widget.otherUser.photoURL == null
                  ? const Icon(Icons.person, size: 80, color: Colors.white70)
                  : null,
            ),
            const SizedBox(height: 20),
            Text(
              widget.otherUser.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.otherUser.email,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            if (widget.callType == CallType.video)
              const Icon(
                Icons.videocam,
                color: Colors.white70,
                size: 32,
              )
            else
              const Icon(
                Icons.call,
                color: Colors.white70,
                size: 32,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallEndedContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 80,
            backgroundColor: Colors.grey[800],
            child: const Icon(
              Icons.call_end,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Call ended',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.otherUser.displayName,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(CallState callState) {
    if (callState == CallState.ended || callState == CallState.failed) {
      return _buildEndedControls();
    }

    if (callState == CallState.ringing && widget.isIncoming) {
      return _buildIncomingCallControls();
    }

    return _buildActiveCallControls();
  }

  Widget _buildIncomingCallControls() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Reject button
          _buildControlButton(
            icon: Icons.call_end,
            color: Colors.red,
            onPressed: () async {
              await _webrtcService.rejectCall();
              Navigator.pop(context);
            },
          ),

          // Answer button
          _buildControlButton(
            icon:
                widget.callType == CallType.video ? Icons.videocam : Icons.call,
            color: Colors.green,
            onPressed: () async {
              await _webrtcService.answerCall();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCallControls() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            color: _isMuted ? Colors.red : Colors.white,
            onPressed: () async {
              setState(() {
                _isMuted = !_isMuted;
              });
              await _webrtcService.toggleMicrophone();
            },
          ),

          // Camera toggle (video calls only)
          if (widget.callType == CallType.video)
            _buildControlButton(
              icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
              color: _isCameraOff ? Colors.red : Colors.white,
              onPressed: () async {
                setState(() {
                  _isCameraOff = !_isCameraOff;
                });
                await _webrtcService.toggleCamera();
              },
            ),

          // Speaker button
          _buildControlButton(
            icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
            color: _isSpeakerOn ? Colors.blue : Colors.white,
            onPressed: () {
              setState(() {
                _isSpeakerOn = !_isSpeakerOn;
              });
              // TODO: Implement speaker toggle
            },
          ),

          // Switch camera (video calls only)
          if (widget.callType == CallType.video)
            _buildControlButton(
              icon: Icons.switch_camera,
              color: Colors.white,
              onPressed: () async {
                await _webrtcService.switchCamera();
              },
            ),

          // End call button
          _buildControlButton(
            icon: Icons.call_end,
            color: Colors.red,
            onPressed: () async {
              await _webrtcService.endCall();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEndedControls() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
        child: const Text(
          'Close',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(
          icon,
          color: color,
          size: 28,
        ),
      ),
    );
  }
}
