import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hamrochat/models/user_model.dart';
import 'package:hamrochat/services/socket_service.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final SocketService _socketService = SocketService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserModel?> signUpWithEmailPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(displayName);
        
        // Get FCM token
        final fcmToken = await _messaging.getToken() ?? '';

        // Create user document in Firestore
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          displayName: displayName,
          photoURL: credential.user!.photoURL,
          phoneNumber: credential.user!.phoneNumber,
          isOnline: true,
          lastSeen: DateTime.now(),
          createdAt: DateTime.now(),
          blockedUsers: [],
          fcmToken: fcmToken,
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toMap());

        // Connect to socket
        final token = await credential.user!.getIdToken();
        if (token != null) {
          _socketService.connect(credential.user!.uid, token);
        }

        return userModel;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred during sign up');
    }
    return null;
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update FCM token and online status
        final fcmToken = await _messaging.getToken() ?? '';
        
        await _firestore.collection('users').doc(credential.user!.uid).update({
          'isOnline': true,
          'lastSeen': DateTime.now().millisecondsSinceEpoch,
          'fcmToken': fcmToken,
        });

        // Get user data
        final userDoc = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        if (userDoc.exists) {
          final userModel = UserModel.fromMap(userDoc.data()!);
          
          // Connect to socket
          final token = await credential.user!.getIdToken();
          if (token != null) {
            _socketService.connect(credential.user!.uid, token);
          }
          
          return userModel;
        }
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred during sign in');
    }
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (currentUser != null) {
        // Update offline status
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'isOnline': false,
          'lastSeen': DateTime.now().millisecondsSinceEpoch,
        });

        // Disconnect socket
        _socketService.disconnect();
      }
      
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error signing out');
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data()!);
      }
    } catch (e) {
      throw Exception('Error fetching user data');
    }
    return null;
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      await _firestore
          .collection('users')
          .doc(updatedUser.uid)
          .update(updatedUser.toMap());
    } catch (e) {
      throw Exception('Error updating user profile');
    }
  }

  // Update user online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'isOnline': isOnline,
          'lastSeen': DateTime.now().millisecondsSinceEpoch,
        });

        _socketService.updateOnlineStatus(isOnline);
      }
    } catch (e) {
      throw Exception('Error updating online status');
    }
  }

  // Search users by email or display name
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.isEmpty) {
        // If no query, return recent users (excluding current user)
        final allUsersQuery = await _firestore
            .collection('users')
            .limit(20)
            .get();
        
        final currentUserId = currentUser?.uid;
        return allUsersQuery.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .where((user) => user.uid != currentUserId)
            .toList();
      }

      final searchQuery = query.toLowerCase().trim();
      
      // Search by display name (case insensitive)
      final nameResults = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: '${query}z')
          .limit(10)
          .get();

      // Search by email (case insensitive)  
      final emailResults = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: searchQuery)
          .where('email', isLessThan: '${searchQuery}z')
          .limit(10)
          .get();

      // Combine results and remove duplicates
      final allResults = <UserModel>[];
      final seenUids = <String>{};
      final currentUserId = currentUser?.uid;

      // Add name search results
      for (var doc in nameResults.docs) {
        final user = UserModel.fromMap(doc.data());
        if (user.uid != currentUserId && !seenUids.contains(user.uid)) {
          allResults.add(user);
          seenUids.add(user.uid);
        }
      }

      // Add email search results
      for (var doc in emailResults.docs) {
        final user = UserModel.fromMap(doc.data());
        if (user.uid != currentUserId && !seenUids.contains(user.uid)) {
          allResults.add(user);
          seenUids.add(user.uid);
        }
      }

      // Also search for partial matches in display name (case insensitive)
      final allUsersQuery = await _firestore
          .collection('users')
          .limit(50)
          .get();
      
      for (var doc in allUsersQuery.docs) {
        final user = UserModel.fromMap(doc.data());
        if (user.uid != currentUserId && !seenUids.contains(user.uid)) {
          final displayName = user.displayName.toLowerCase();
          final email = user.email.toLowerCase();
          
          if (displayName.contains(searchQuery) || email.contains(searchQuery)) {
            allResults.add(user);
            seenUids.add(user.uid);
          }
        }
      }

      print('Search query: "$query", found ${allResults.length} users');
      return allResults.take(20).toList();
    } catch (e) {
      print('Error searching users: $e');
      throw Exception('Error searching users: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error sending password reset email');
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      default:
        return 'An authentication error occurred: ${e.message}';
    }
  }
}
