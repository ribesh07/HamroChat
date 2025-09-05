import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hamrochat/models/chat_model.dart';
import 'package:hamrochat/models/message_model.dart';
import 'package:hamrochat/models/user_model.dart';
import 'package:hamrochat/services/socket_service.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SocketService _socketService = SocketService();
  final Uuid _uuid = const Uuid();

  String? get currentUserId => _auth.currentUser?.uid;

  // Get user's chats stream
  Stream<List<ChatModel>> getUserChats() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .where('isActive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromMap(doc.data()))
            .toList());
  }

  // Get messages for a chat
  Stream<List<MessageModel>> getChatMessages(String chatId, {int limit = 50}) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }

  // Create or get one-on-one chat
  Future<ChatModel> createOrGetOneOnOneChat(String otherUserId, UserModel otherUser) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    // Check if chat already exists
    final existingChats = await _firestore
        .collection('chats')
        .where('type', isEqualTo: ChatType.oneOnOne.index)
        .where('participants', arrayContains: currentUserId)
        .get();

    for (var doc in existingChats.docs) {
      final chat = ChatModel.fromMap(doc.data());
      if (chat.participants.contains(otherUserId)) {
        return chat;
      }
    }

    // Create new chat
    final chatId = _uuid.v4();
    final now = DateTime.now();
    
    final newChat = ChatModel(
      chatId: chatId,
      chatName: otherUser.displayName,
      chatImage: otherUser.photoURL,
      type: ChatType.oneOnOne,
      participants: [currentUserId!, otherUserId],
      createdAt: now,
      updatedAt: now,
      createdBy: currentUserId!,
      admins: [],
      unreadCount: {currentUserId!: 0, otherUserId: 0},
      isActive: true,
    );

    await _firestore
        .collection('chats')
        .doc(chatId)
        .set(newChat.toMap());

    return newChat;
  }

  // Create group chat
  Future<ChatModel> createGroupChat({
    required String groupName,
    required List<String> participantIds,
    String? description,
    File? groupImage,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final chatId = _uuid.v4();
    final now = DateTime.now();
    String? imageUrl;

    // Upload group image if provided
    if (groupImage != null) {
      imageUrl = await _uploadFile(groupImage, 'group_images/$chatId');
    }

    // Include current user in participants
    final allParticipants = [currentUserId!, ...participantIds];
    final unreadCount = <String, int>{};
    for (String userId in allParticipants) {
      unreadCount[userId] = 0;
    }

    final newChat = ChatModel(
      chatId: chatId,
      chatName: groupName,
      chatImage: imageUrl,
      type: ChatType.group,
      participants: allParticipants,
      createdAt: now,
      updatedAt: now,
      createdBy: currentUserId!,
      admins: [currentUserId!],
      unreadCount: unreadCount,
      isActive: true,
      description: description,
    );

    await _firestore
        .collection('chats')
        .doc(chatId)
        .set(newChat.toMap());

    return newChat;
  }

  // Send text message
  Future<void> sendTextMessage(String chatId, String content) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final messageId = _uuid.v4();
    final now = DateTime.now();

    // Get current user info
    final userDoc = await _firestore.collection('users').doc(currentUserId).get();
    final userData = userDoc.data()!;

    final message = MessageModel(
      messageId: messageId,
      chatId: chatId,
      senderId: currentUserId!,
      senderName: userData['displayName'] ?? '',
      senderPhotoURL: userData['photoURL'],
      content: content,
      type: MessageType.text,
      status: MessageStatus.sending,
      timestamp: now,
      readBy: [],
    );

    // Add message to Firestore
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set(message.toMap());

    // Update chat's last message info
    await _updateChatLastMessage(chatId, content, now);

    // Send via socket for real-time delivery
    _socketService.sendMessage(message.copyWith(status: MessageStatus.sent));
  }

  // Send image message
  Future<void> sendImageMessage(String chatId, File imageFile) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final messageId = _uuid.v4();
    final now = DateTime.now();

    // Get current user info
    final userDoc = await _firestore.collection('users').doc(currentUserId).get();
    final userData = userDoc.data()!;

    // Create initial message with sending status
    final message = MessageModel(
      messageId: messageId,
      chatId: chatId,
      senderId: currentUserId!,
      senderName: userData['displayName'] ?? '',
      senderPhotoURL: userData['photoURL'],
      content: 'Image',
      type: MessageType.image,
      status: MessageStatus.sending,
      timestamp: now,
      readBy: [],
      fileSize: await imageFile.length(),
    );

    // Add message to Firestore
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set(message.toMap());

    try {
      // Upload image to Firebase Storage
      final imageUrl = await _uploadFile(imageFile, 'chat_images/$chatId/$messageId');

      // Update message with image URL
      final updatedMessage = message.copyWith(
        fileURL: imageUrl,
        status: MessageStatus.sent,
      );

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update(updatedMessage.toMap());

      // Update chat's last message info
      await _updateChatLastMessage(chatId, 'Image', now);

      // Send via socket for real-time delivery
      _socketService.sendMessage(updatedMessage);
    } catch (e) {
      // Update message status to failed
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'status': MessageStatus.failed.index});
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, List<String> messageIds) async {
    if (currentUserId == null) return;

    final batch = _firestore.batch();
    
    for (String messageId in messageIds) {
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);
      
      batch.update(messageRef, {
        'readBy': FieldValue.arrayUnion([currentUserId]),
        'readAt': DateTime.now().millisecondsSinceEpoch,
        'status': MessageStatus.read.index,
      });
    }

    await batch.commit();

    // Send read receipts via socket
    _socketService.markMessagesAsRead(messageIds, chatId);

    // Reset unread count for current user
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount.$currentUserId': 0,
    });
  }

  // Add participant to group chat
  Future<void> addParticipantToGroup(String chatId, String userId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _firestore.collection('chats').doc(chatId).update({
      'participants': FieldValue.arrayUnion([userId]),
      'unreadCount.$userId': 0,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Remove participant from group chat
  Future<void> removeParticipantFromGroup(String chatId, String userId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _firestore.collection('chats').doc(chatId).update({
      'participants': FieldValue.arrayRemove([userId]),
      'unreadCount.$userId': FieldValue.delete(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Update group info
  Future<void> updateGroupInfo({
    required String chatId,
    String? groupName,
    String? description,
    File? groupImage,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    if (groupName != null) updates['chatName'] = groupName;
    if (description != null) updates['description'] = description;

    if (groupImage != null) {
      final imageUrl = await _uploadFile(groupImage, 'group_images/$chatId');
      updates['chatImage'] = imageUrl;
    }

    await _firestore.collection('chats').doc(chatId).update(updates);
  }

  // Get chat details
  Future<ChatModel?> getChatDetails(String chatId) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        return ChatModel.fromMap(chatDoc.data()!);
      }
    } catch (e) {
      throw Exception('Error fetching chat details');
    }
    return null;
  }

  // Delete chat
  Future<void> deleteChat(String chatId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    // For one-on-one chats, just set as inactive for current user
    // For groups, remove current user from participants
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (chatDoc.exists) {
      final chat = ChatModel.fromMap(chatDoc.data()!);
      
      if (chat.type == ChatType.oneOnOne) {
        // Mark as inactive for current user (you might implement this differently)
        await _firestore.collection('chats').doc(chatId).update({
          'isActive': false,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        // Remove from group
        await removeParticipantFromGroup(chatId, currentUserId!);
      }
    }
  }

  // Helper method to upload files
  Future<String> _uploadFile(File file, String path) async {
    final ref = _storage.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // Helper method to update chat's last message
  Future<void> _updateChatLastMessage(String chatId, String lastMessage, DateTime timestamp) async {
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': lastMessage,
      'lastMessageTime': timestamp.millisecondsSinceEpoch,
      'lastMessageSenderId': currentUserId,
      'updatedAt': timestamp.millisecondsSinceEpoch,
    });
  }

  // Get unread message count for a chat
  Future<int> getUnreadMessageCount(String chatId) async {
    if (currentUserId == null) return 0;

    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (chatDoc.exists) {
      final chat = ChatModel.fromMap(chatDoc.data()!);
      return chat.getUnreadCount(currentUserId!);
    }
    return 0;
  }
}
