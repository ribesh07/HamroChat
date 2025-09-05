import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hamrochat/models/user_model.dart';

class DebugHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> addTestUsers() async {
    try {
      // Add some test users to help with testing
      final testUsers = [
        UserModel(
          uid: 'test_user_1',
          email: 'alice@example.com',
          displayName: 'Alice Johnson',
          photoURL: null,
          phoneNumber: '+1234567890',
          isOnline: false,
          lastSeen: DateTime.now().subtract(const Duration(hours: 1)),
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          blockedUsers: [],
          fcmToken: '',
        ),
        UserModel(
          uid: 'test_user_2',
          email: 'bob@example.com',
          displayName: 'Bob Smith',
          photoURL: null,
          phoneNumber: '+9876543210',
          isOnline: true,
          lastSeen: DateTime.now(),
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          blockedUsers: [],
          fcmToken: '',
        ),
        UserModel(
          uid: 'test_user_3',
          email: 'charlie@example.com',
          displayName: 'Charlie Brown',
          photoURL: null,
          phoneNumber: '+5555555555',
          isOnline: false,
          lastSeen: DateTime.now().subtract(const Duration(minutes: 30)),
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          blockedUsers: [],
          fcmToken: '',
        ),
      ];

      for (final user in testUsers) {
        await _firestore.collection('users').doc(user.uid).set(user.toMap());
      }

      print('Added ${testUsers.length} test users to the database');
    } catch (e) {
      print('Error adding test users: $e');
    }
  }

  static Future<void> listAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      print('Total users in database: ${snapshot.docs.length}');
      
      for (final doc in snapshot.docs) {
        final user = UserModel.fromMap(doc.data());
        print('User: ${user.displayName} (${user.email}) - Online: ${user.isOnline}');
      }
    } catch (e) {
      print('Error listing users: $e');
    }
  }

  static Future<void> removeTestUsers() async {
    try {
      final testUserIds = ['test_user_1', 'test_user_2', 'test_user_3'];
      
      for (final uid in testUserIds) {
        await _firestore.collection('users').doc(uid).delete();
      }
      
      print('Removed test users from the database');
    } catch (e) {
      print('Error removing test users: $e');
    }
  }
}
