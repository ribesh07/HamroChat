import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hamrochat/services/webrtc_service.dart';

class CallHistoryModel {
  final String callId;
  final String callerId;
  final String receiverId;
  final String callerName;
  final String receiverName;
  final String? callerPhotoURL;
  final String? receiverPhotoURL;
  final CallType callType;
  final CallStatus callStatus;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final bool isIncoming;

  CallHistoryModel({
    required this.callId,
    required this.callerId,
    required this.receiverId,
    required this.callerName,
    required this.receiverName,
    this.callerPhotoURL,
    this.receiverPhotoURL,
    required this.callType,
    required this.callStatus,
    required this.startTime,
    this.endTime,
    this.duration,
    required this.isIncoming,
  });

  factory CallHistoryModel.fromMap(Map<String, dynamic> map) {
    try {
      return CallHistoryModel(
        callId: map['callId']?.toString() ?? '',
        callerId: map['callerId']?.toString() ?? '',
        receiverId: map['receiverId']?.toString() ?? '',
        callerName: map['callerName']?.toString() ?? '',
        receiverName: map['receiverName']?.toString() ?? '',
        callerPhotoURL: map['callerPhotoURL']?.toString(),
        receiverPhotoURL: map['receiverPhotoURL']?.toString(),
        callType: CallType.values[map['callType'] is int ? map['callType'] : 0],
        callStatus:
            CallStatus.values[map['callStatus'] is int ? map['callStatus'] : 0],
        startTime: map['startTime'] is Timestamp
            ? (map['startTime'] as Timestamp).toDate()
            : DateTime.now(),
        endTime: map['endTime'] is Timestamp
            ? (map['endTime'] as Timestamp).toDate()
            : null,
        duration: map['duration'] is int
            ? Duration(seconds: map['duration'] as int)
            : null,
        isIncoming: map['isIncoming'] is bool ? map['isIncoming'] : false,
      );
    } catch (e) {
      print('❌ Error parsing call history model: $e');
      print('❌ Map data: $map');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'callerId': callerId,
      'receiverId': receiverId,
      'callerName': callerName,
      'receiverName': receiverName,
      'callerPhotoURL': callerPhotoURL,
      'receiverPhotoURL': receiverPhotoURL,
      'callType': callType.index,
      'callStatus': callStatus.index,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'duration': duration?.inSeconds,
      'isIncoming': isIncoming,
    };
  }

  CallHistoryModel copyWith({
    String? callId,
    String? callerId,
    String? receiverId,
    String? callerName,
    String? receiverName,
    String? callerPhotoURL,
    String? receiverPhotoURL,
    CallType? callType,
    CallStatus? callStatus,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    bool? isIncoming,
  }) {
    return CallHistoryModel(
      callId: callId ?? this.callId,
      callerId: callerId ?? this.callerId,
      receiverId: receiverId ?? this.receiverId,
      callerName: callerName ?? this.callerName,
      receiverName: receiverName ?? this.receiverName,
      callerPhotoURL: callerPhotoURL ?? this.callerPhotoURL,
      receiverPhotoURL: receiverPhotoURL ?? this.receiverPhotoURL,
      callType: callType ?? this.callType,
      callStatus: callStatus ?? this.callStatus,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      isIncoming: isIncoming ?? this.isIncoming,
    );
  }

  @override
  String toString() {
    return 'CallHistoryModel(callId: $callId, callerId: $callerId, receiverId: $receiverId, callerName: $callerName, receiverName: $receiverName, callType: $callType, callStatus: $callStatus, startTime: $startTime, endTime: $endTime, duration: $duration, isIncoming: $isIncoming)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CallHistoryModel &&
        other.callId == callId &&
        other.callerId == callerId &&
        other.receiverId == receiverId;
  }

  @override
  int get hashCode {
    return callId.hashCode ^ callerId.hashCode ^ receiverId.hashCode;
  }
}

enum CallStatus {
  missed,
  answered,
  rejected,
  failed,
  ongoing,
}

extension CallStatusExtension on CallStatus {
  String get displayName {
    switch (this) {
      case CallStatus.missed:
        return 'Missed';
      case CallStatus.answered:
        return 'Answered';
      case CallStatus.rejected:
        return 'Rejected';
      case CallStatus.failed:
        return 'Failed';
      case CallStatus.ongoing:
        return 'Ongoing';
    }
  }

  String get icon {
    switch (this) {
      case CallStatus.missed:
        return '📞';
      case CallStatus.answered:
        return '✅';
      case CallStatus.rejected:
        return '❌';
      case CallStatus.failed:
        return '⚠️';
      case CallStatus.ongoing:
        return '🔄';
    }
  }
}
