import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hamrochat/models/user_model.dart';
import 'package:hamrochat/models/chat_model.dart';
import 'package:hamrochat/models/message_model.dart';
import 'package:hamrochat/repositories/auth_repository.dart';
import 'package:hamrochat/repositories/chat_repository.dart';
import 'package:hamrochat/services/socket_service.dart';

// Repository providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return authRepository.authStateChanges;
});

// Current user provider
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authRepository = ref.read(authRepositoryProvider);
  final user = authRepository.currentUser;
  if (user != null) {
    return await authRepository.getUserById(user.uid);
  }
  return null;
});

// Auth loading state
final authLoadingProvider = StateProvider<bool>((ref) => false);

// Auth error provider
final authErrorProvider = StateProvider<String?>((ref) => null);

// Chat state providers
final selectedChatProvider = StateProvider<ChatModel?>((ref) => null);

final chatLoadingProvider = StateProvider<bool>((ref) => false);

final chatErrorProvider = StateProvider<String?>((ref) => null);

// User chats stream provider
final userChatsProvider = StreamProvider<List<ChatModel>>((ref) {
  final chatRepository = ref.read(chatRepositoryProvider);
  return chatRepository.getUserChats();
});

// Chat messages stream provider
final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  final chatRepository = ref.read(chatRepositoryProvider);
  return chatRepository.getChatMessages(chatId);
});

// Socket message stream provider
final socketMessageStreamProvider = StreamProvider<MessageModel>((ref) {
  final socketService = ref.read(socketServiceProvider);
  return socketService.messageStream;
});

// Socket status stream provider
final socketStatusStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final socketService = ref.read(socketServiceProvider);
  return socketService.statusStream;
});

// Typing indicator stream provider
final typingIndicatorProvider = StreamProvider<String>((ref) {
  final socketService = ref.read(socketServiceProvider);
  return socketService.typingStream;
});

// Online users stream provider
final onlineUsersProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final socketService = ref.read(socketServiceProvider);
  return socketService.onlineUsersStream;
});

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Search results provider
final searchUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  print('Search provider called with query: "$query"');
  
  final authRepository = ref.read(authRepositoryProvider);
  final results = await authRepository.searchUsers(query);
  print('Search provider returning ${results.length} users');
  return results;
});

// Selected participants for group chat
final selectedParticipantsProvider = StateProvider<List<UserModel>>((ref) => []);

// Message input controller states
final messageTextProvider = StateProvider<String>((ref) => '');
final isTypingProvider = StateProvider<bool>((ref) => false);

// Image picker states
final selectedImageProvider = StateProvider<String?>((ref) => null);
final isImageUploadingProvider = StateProvider<bool>((ref) => false);

// Chat creation states
final chatCreationLoadingProvider = StateProvider<bool>((ref) => false);
final groupNameProvider = StateProvider<String>((ref) => '');
final groupDescriptionProvider = StateProvider<String>((ref) => '');

// Unread messages count provider
final unreadCountProvider = FutureProvider.family<int, String>((ref, chatId) async {
  final chatRepository = ref.read(chatRepositoryProvider);
  return await chatRepository.getUnreadMessageCount(chatId);
});

// Auth methods provider
final authMethodsProvider = Provider<AuthMethods>((ref) {
  return AuthMethods(ref);
});

final chatMethodsProvider = Provider<ChatMethods>((ref) {
  return ChatMethods(ref);
});

// Auth methods class
class AuthMethods {
  final Ref ref;
  AuthMethods(this.ref);

  Future<void> signUp(String email, String password, String displayName) async {
    try {
      ref.read(authLoadingProvider.notifier).state = true;
      ref.read(authErrorProvider.notifier).state = null;

      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signUpWithEmailPassword(email, password, displayName);
    } catch (e) {
      ref.read(authErrorProvider.notifier).state = e.toString();
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      ref.read(authLoadingProvider.notifier).state = true;
      ref.read(authErrorProvider.notifier).state = null;

      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signInWithEmailPassword(email, password);
    } catch (e) {
      ref.read(authErrorProvider.notifier).state = e.toString();
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<void> signOut() async {
    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signOut();
    } catch (e) {
      ref.read(authErrorProvider.notifier).state = e.toString();
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      ref.read(authLoadingProvider.notifier).state = true;
      ref.read(authErrorProvider.notifier).state = null;

      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.resetPassword(email);
    } catch (e) {
      ref.read(authErrorProvider.notifier).state = e.toString();
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }
}

// Chat methods class
class ChatMethods {
  final Ref ref;
  ChatMethods(this.ref);

  Future<void> sendTextMessage(String chatId, String content) async {
    try {
      final chatRepository = ref.read(chatRepositoryProvider);
      await chatRepository.sendTextMessage(chatId, content);
      ref.read(messageTextProvider.notifier).state = '';
    } catch (e) {
      ref.read(chatErrorProvider.notifier).state = e.toString();
    }
  }

  Future<void> sendImageMessage(String chatId, dynamic imageFile) async {
    try {
      ref.read(isImageUploadingProvider.notifier).state = true;
      final chatRepository = ref.read(chatRepositoryProvider);
      await chatRepository.sendImageMessage(chatId, imageFile);
    } catch (e) {
      ref.read(chatErrorProvider.notifier).state = e.toString();
    } finally {
      ref.read(isImageUploadingProvider.notifier).state = false;
    }
  }

  Future<ChatModel?> createOrGetOneOnOneChat(String otherUserId, UserModel otherUser) async {
    try {
      ref.read(chatLoadingProvider.notifier).state = true;
      final chatRepository = ref.read(chatRepositoryProvider);
      return await chatRepository.createOrGetOneOnOneChat(otherUserId, otherUser);
    } catch (e) {
      ref.read(chatErrorProvider.notifier).state = e.toString();
      return null;
    } finally {
      ref.read(chatLoadingProvider.notifier).state = false;
    }
  }

  Future<ChatModel?> createGroupChat({
    required String groupName,
    required List<String> participantIds,
    String? description,
    dynamic groupImage,
  }) async {
    try {
      ref.read(chatCreationLoadingProvider.notifier).state = true;
      final chatRepository = ref.read(chatRepositoryProvider);
      return await chatRepository.createGroupChat(
        groupName: groupName,
        participantIds: participantIds,
        description: description,
        groupImage: groupImage,
      );
    } catch (e) {
      ref.read(chatErrorProvider.notifier).state = e.toString();
      return null;
    } finally {
      ref.read(chatCreationLoadingProvider.notifier).state = false;
    }
  }

  Future<void> markMessagesAsRead(String chatId, List<String> messageIds) async {
    try {
      final chatRepository = ref.read(chatRepositoryProvider);
      await chatRepository.markMessagesAsRead(chatId, messageIds);
    } catch (e) {
      ref.read(chatErrorProvider.notifier).state = e.toString();
    }
  }

  void startTyping(String chatId) {
    final socketService = ref.read(socketServiceProvider);
    socketService.sendTypingIndicator(chatId, true);
    ref.read(isTypingProvider.notifier).state = true;
  }

  void stopTyping(String chatId) {
    final socketService = ref.read(socketServiceProvider);
    socketService.sendTypingIndicator(chatId, false);
    ref.read(isTypingProvider.notifier).state = false;
  }

  void joinChatRoom(String chatId) {
    final socketService = ref.read(socketServiceProvider);
    socketService.joinChatRoom(chatId);
  }

  void leaveChatRoom(String chatId) {
    final socketService = ref.read(socketServiceProvider);
    socketService.leaveChatRoom(chatId);
  }
}
