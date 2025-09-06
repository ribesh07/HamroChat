import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hamrochat/providers/providers.dart';
import 'package:hamrochat/services/webrtc_service.dart';
import 'package:hamrochat/screens/call/call_screen.dart';
import 'package:hamrochat/models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OngoingCallIndicator extends ConsumerWidget {
  const OngoingCallIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callInfo = ref.watch(currentCallInfoProvider);

    if (callInfo == null) {
      return const SizedBox.shrink();
    }

    final callType = callInfo['callType'] as CallType?;
    final otherUser = callInfo['otherUser'] as UserModel?;
    final callState = callInfo['callState'] as CallState?;

    if (otherUser == null || callType == null || callState == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // User avatar
          CircleAvatar(
            radius: 24,
            backgroundImage: otherUser.photoURL != null
                ? CachedNetworkImageProvider(otherUser.photoURL!)
                : null,
            child: otherUser.photoURL == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),

          // Call info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  otherUser.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      callType == CallType.video ? Icons.videocam : Icons.call,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getCallStatusText(callState),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Return to call button
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CallScreen(
                        otherUser: otherUser,
                        callType: callType,
                        isIncoming: false,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.phone,
                  color: Colors.white,
                ),
                tooltip: 'Return to call',
              ),

              // End call button
              IconButton(
                onPressed: () async {
                  final webrtcService = ref.read(webrtcServiceProvider);
                  await webrtcService.endCall();
                },
                icon: const Icon(
                  Icons.call_end,
                  color: Colors.red,
                ),
                tooltip: 'End call',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCallStatusText(CallState callState) {
    switch (callState) {
      case CallState.calling:
        return 'Calling...';
      case CallState.ringing:
        return 'Ringing...';
      case CallState.connected:
        return 'Connected';
      case CallState.ended:
        return 'Call ended';
      case CallState.failed:
        return 'Call failed';
      default:
        return 'Unknown';
    }
  }
}
