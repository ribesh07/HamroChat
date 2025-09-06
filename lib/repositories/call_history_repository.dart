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

      print('💾 Saving call history to: $_collection/$callId');
      print('💾 Call history data: ${callHistory.toMap()}');

      // Try saving to direct collection first
      await _firestore
          .collection(_collection)
          .doc(callId)
          .set(callHistory.toMap());

      // Also save to subcollection structure for compatibility
      await _firestore
          .collection(_collection)
          .doc(callId)
          .collection('info')
          .doc('call_data')
          .set(callHistory.toMap());

      print('✅ Call history saved successfully to both locations');
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

  // // Get call history for a user
  // Stream<List<CallHistoryModel>> getCallHistory(String userId) {
  //   return _firestore
  //       .collection(_collection)
  //       .where('callerId', isEqualTo: userId)
  //       .orderBy('startTime', descending: true)
  //       .snapshots()
  //       .map((snapshot) {
  //     return snapshot.docs
  //         .map((doc) => CallHistoryModel.fromMap(doc.data()))
  //         .toList();
  //   });
  // }

  Stream<List<CallHistoryModel>> getCallHistory(String userId) {
    return _firestore
        .collection(_collection)
        .where('callerId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CallHistoryModel.fromMap({
          ...data,
          'id': doc.id, // attach Firestore doc id
        });
      }).toList();
    });
  }

  // Get call history for a user (including incoming calls)
  Stream<List<CallHistoryModel>> getAllCallHistory(String userId) {
    print('🔍 Querying call history for user: $userId');
    print('🔍 Collection: $_collection');

    // First try the direct collection approach
    return _firestore
        .collection(_collection)
        .where('callerId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .asyncMap((outgoingSnapshot) async {
      try {
        print(
            '📞 Outgoing calls query result: ${outgoingSnapshot.docs.length} docs');

        // Get outgoing calls
        final outgoingCalls = outgoingSnapshot.docs.map((doc) {
          print('📞 Outgoing call doc: ${doc.id} -> ${doc.data()}');
          return CallHistoryModel.fromMap(doc.data());
        }).toList();

        // Get incoming calls
        print('🔍 Querying incoming calls...');
        final incomingSnapshot = await _firestore
            .collection(_collection)
            .where('receiverId', isEqualTo: userId)
            .orderBy('startTime', descending: true)
            .get();

        print(
            '📞 Incoming calls query result: ${incomingSnapshot.docs.length} docs');
        final incomingCalls = incomingSnapshot.docs.map((doc) {
          print('📞 Incoming call doc: ${doc.id} -> ${doc.data()}');
          return CallHistoryModel.fromMap(doc.data());
        }).toList();

        // If no calls found in direct collection, try subcollection approach
        if (outgoingCalls.isEmpty && incomingCalls.isEmpty) {
          print(
              '🔍 No calls found in direct collection, trying subcollection approach...');
          return await _getCallHistoryFromSubcollections(userId);
        }

        // Combine and sort by start time
        final allCalls = [...outgoingCalls, ...incomingCalls];
        allCalls.sort((a, b) => b.startTime.compareTo(a.startTime));

        print(
            '📞 Total call history records: ${allCalls.length} for user $userId');
        return allCalls;
      } catch (e) {
        print('❌ Error loading call history: $e');
        print('❌ Stack trace: ${StackTrace.current}');
        return <CallHistoryModel>[];
      }
    });
  }

  // Alternative method to get call history from subcollections
  Future<List<CallHistoryModel>> _getCallHistoryFromSubcollections(
      String userId) async {
    try {
      print('🔍 Trying subcollection approach for user: $userId');

      // Get all documents in call_history collection
      final allDocsSnapshot = await _firestore.collection(_collection).get();
      print(
          '📞 Found ${allDocsSnapshot.docs.length} documents in call_history collection');

      final allCalls = <CallHistoryModel>[];

      for (var doc in allDocsSnapshot.docs) {
        print('🔍 Checking document: ${doc.id}');

        // Check if this document has an 'info' subcollection
        final infoSnapshot = await doc.reference.collection('info').get();
        print(
            '📞 Document ${doc.id} has ${infoSnapshot.docs.length} info subdocuments');

        for (var infoDoc in infoSnapshot.docs) {
          print('📞 Info doc: ${infoDoc.id} -> ${infoDoc.data()}');

          try {
            final callData = infoDoc.data();
            // Check if this call involves the current user
            if (callData['callerId'] == userId ||
                callData['receiverId'] == userId) {
              final call = CallHistoryModel.fromMap(callData);
              allCalls.add(call);
              print('✅ Added call: ${call.callId}');
            }
          } catch (e) {
            print('❌ Error parsing call data from subcollection: $e');
          }
        }
      }

      // Sort by start time
      allCalls.sort((a, b) => b.startTime.compareTo(a.startTime));

      print(
          '📞 Found ${allCalls.length} calls in subcollections for user $userId');
      return allCalls;
    } catch (e) {
      print('❌ Error loading call history from subcollections: $e');
      return <CallHistoryModel>[];
    }
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
