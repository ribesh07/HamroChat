import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hamrochat/models/call_history_model.dart';
import 'package:hamrochat/services/webrtc_service.dart';

class CallHistoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'call_history';

  // Save call history
  Future<void> saveCallHistory({
    required String callId,
    required String callerId,
    required String receiverId,
    required String callerName,
    required String receiverName,
    String? callerPhotoURL,
    String? receiverPhotoURL,
    required CallType callType,
    required CallStatus callStatus,
    required DateTime startTime,
    DateTime? endTime,
    Duration? duration,
    required bool isIncoming,
  }) async {
    try {
      final callHistory = CallHistoryModel(
        callId: callId,
        callerId: callerId,
        receiverId: receiverId,
        callerName: callerName,
        receiverName: receiverName,
        callerPhotoURL: callerPhotoURL,
        receiverPhotoURL: receiverPhotoURL,
        callType: callType,
        callStatus: callStatus,
        startTime: startTime,
        endTime: endTime,
        duration: duration,
        isIncoming: isIncoming,
      );

      await _firestore
          .collection(_collection)
          .doc(callId)
          .set(callHistory.toMap());
    } catch (e) {
      throw Exception('Failed to save call history: $e');
    }
  }

  // Update call status
  Future<void> updateCallStatus({
    required String callId,
    required CallStatus callStatus,
    DateTime? endTime,
    Duration? duration,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'callStatus': callStatus.index,
      };

      if (endTime != null) {
        updateData['endTime'] = Timestamp.fromDate(endTime);
      }

      if (duration != null) {
        updateData['duration'] = duration.inSeconds;
      }

      await _firestore.collection(_collection).doc(callId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update call status: $e');
    }
  }

  // Get call history for a user
  Stream<List<CallHistoryModel>> getCallHistory(String userId) {
    return _firestore
        .collection(_collection)
        .where('callerId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CallHistoryModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Get call history for a user (including incoming calls)
  Stream<List<CallHistoryModel>> getAllCallHistory(String userId) {
    return _firestore
        .collection(_collection)
        .where(Filter.or(
          Filter('callerId', isEqualTo: userId),
          Filter('receiverId', isEqualTo: userId),
        ))
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs
            .map((doc) => CallHistoryModel.fromMap(doc.data()))
            .toList();
      } catch (e) {
        print('Error parsing call history: $e');
        return <CallHistoryModel>[];
      }
    });
  }

  // Get call history between two users
  Stream<List<CallHistoryModel>> getCallHistoryBetweenUsers(
      String userId1, String userId2) {
    return _firestore
        .collection(_collection)
        .where(Filter.or(
          Filter.and(
            Filter('callerId', isEqualTo: userId1),
            Filter('receiverId', isEqualTo: userId2),
          ),
          Filter.and(
            Filter('callerId', isEqualTo: userId2),
            Filter('receiverId', isEqualTo: userId1),
          ),
        ))
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CallHistoryModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Delete call history
  Future<void> deleteCallHistory(String callId) async {
    try {
      await _firestore.collection(_collection).doc(callId).delete();
    } catch (e) {
      throw Exception('Failed to delete call history: $e');
    }
  }

  // Clear all call history for a user
  Future<void> clearCallHistory(String userId) async {
    try {
      final batch = _firestore.batch();

      // Get all call history documents for the user
      final outgoingCalls = await _firestore
          .collection(_collection)
          .where('callerId', isEqualTo: userId)
          .get();

      final incomingCalls = await _firestore
          .collection(_collection)
          .where('receiverId', isEqualTo: userId)
          .get();

      // Add all documents to batch for deletion
      for (var doc in outgoingCalls.docs) {
        batch.delete(doc.reference);
      }

      for (var doc in incomingCalls.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear call history: $e');
    }
  }

  // Get call statistics
  Future<Map<String, int>> getCallStatistics(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where(Filter.or(
            Filter('callerId', isEqualTo: userId),
            Filter('receiverId', isEqualTo: userId),
          ))
          .get();

      final calls = snapshot.docs
          .map((doc) => CallHistoryModel.fromMap(doc.data()))
          .toList();

      final stats = <String, int>{
        'total': calls.length,
        'answered': 0,
        'missed': 0,
        'rejected': 0,
        'failed': 0,
        'audio': 0,
        'video': 0,
      };

      for (final call in calls) {
        switch (call.callStatus) {
          case CallStatus.answered:
            stats['answered'] = stats['answered']! + 1;
            break;
          case CallStatus.missed:
            stats['missed'] = stats['missed']! + 1;
            break;
          case CallStatus.rejected:
            stats['rejected'] = stats['rejected']! + 1;
            break;
          case CallStatus.failed:
            stats['failed'] = stats['failed']! + 1;
            break;
          case CallStatus.ongoing:
            break;
        }

        switch (call.callType) {
          case CallType.audio:
            stats['audio'] = stats['audio']! + 1;
            break;
          case CallType.video:
            stats['video'] = stats['video']! + 1;
            break;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get call statistics: $e');
    }
  }
}
