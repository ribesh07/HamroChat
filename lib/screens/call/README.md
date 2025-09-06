# WebRTC Audio/Video Call Implementation

This directory contains the WebRTC implementation for audio and video calls in the HamroChat app.

## Features

- **Audio Calls**: High-quality voice calls between users
- **Video Calls**: Video calls with camera switching and controls
- **Real-time Communication**: Uses WebRTC for peer-to-peer communication
- **Call Controls**: Mute, camera toggle, speaker, and call end controls
- **Call States**: Proper handling of calling, ringing, connected, and ended states

## Files

- `call_screen.dart`: Main UI for call interface
- `webrtc_service.dart`: WebRTC service for handling call logic

## Dependencies

- `flutter_webrtc`: WebRTC implementation for Flutter
- `socket_io_client`: Real-time signaling for call setup

## Usage

### Starting a Call

```dart
// Audio call
await webrtcService.startCall(otherUserId, otherUser, CallType.audio);

// Video call
await webrtcService.startCall(otherUserId, otherUser, CallType.video);
```

### Answering a Call

```dart
await webrtcService.answerCall();
```

### Ending a Call

```dart
await webrtcService.endCall();
```

## Permissions Required

### Android (android/app/src/main/AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

### iOS (ios/Runner/Info.plist)

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access for audio calls</string>
```

## Call Flow

1. **Call Initiation**: User taps call button in chat
2. **Permission Check**: App requests camera/microphone permissions
3. **Media Stream**: Local media stream is created
4. **Peer Connection**: WebRTC peer connection is established
5. **Signaling**: Call offer/answer exchanged via Socket.IO
6. **ICE Candidates**: Network connectivity established
7. **Call Connected**: Media streams are exchanged
8. **Call Controls**: User can mute, toggle camera, etc.
9. **Call End**: Call is terminated and resources cleaned up

## Notes

- Currently works for one-on-one chats only
- Requires proper STUN/TURN server configuration for production
- Call quality depends on network conditions
- Video calls require camera permission
- Audio calls work with microphone permission only
