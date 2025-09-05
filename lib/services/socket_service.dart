import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:hamrochat/models/message_model.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  String? _currentUserId;
  final StreamController<MessageModel> _messageController = StreamController<MessageModel>.broadcast();
  final StreamController<Map<String, dynamic>> _statusController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _typingController = StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _onlineUsersController = StreamController<Map<String, dynamic>>.broadcast();

  // Stream getters
  Stream<MessageModel> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;
  Stream<String> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get onlineUsersStream => _onlineUsersController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String userId, String token) {
    if (_socket != null && _socket!.connected) {
      return;
    }

    _currentUserId = userId;

    _socket = io.io(
      'wss://hamrochat-socket.onrender.com',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({
            'token': token,
            'userId': userId,
          })
          .build(),
    );

    _setupEventListeners();
    _socket!.connect();
  }

  void _setupEventListeners() {
    _socket!.onConnect((_) {
      print('Connected to socket server');
      _joinUserRoom();
    });

    _socket!.onDisconnect((_) {
      print('Disconnected from socket server');
    });

    _socket!.onConnectError((error) {
      print('Connection error: $error');
    });

    // Listen for new messages
    _socket!.on('new_message', (data) {
      try {
        final message = MessageModel.fromMap(Map<String, dynamic>.from(data));
        _messageController.add(message);
      } catch (e) {
        print('Error parsing message: $e');
      }
    });

    // Listen for message status updates
    _socket!.on('message_status_updated', (data) {
      _statusController.add(Map<String, dynamic>.from(data));
    });

    // Listen for typing indicators
    _socket!.on('user_typing', (data) {
      _typingController.add(data['chatId'] ?? '');
    });

    // Listen for online users updates
    _socket!.on('online_users_updated', (data) {
      _onlineUsersController.add(Map<String, dynamic>.from(data));
    });

    // Listen for message delivery confirmations
    _socket!.on('message_delivered', (data) {
      _statusController.add({
        'messageId': data['messageId'],
        'status': 'delivered',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });

    // Listen for message read confirmations
    _socket!.on('message_read', (data) {
      _statusController.add({
        'messageId': data['messageId'],
        'status': 'read',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'readBy': data['readBy'],
      });
    });
  }

  void _joinUserRoom() {
    if (_currentUserId != null) {
      _socket!.emit('join_user_room', {'userId': _currentUserId});
    }
  }

  void joinChatRoom(String chatId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_chat', {'chatId': chatId});
    }
  }

  void leaveChatRoom(String chatId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('leave_chat', {'chatId': chatId});
    }
  }

  void sendMessage(MessageModel message) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('send_message', message.toMap());
    }
  }

  void sendTypingIndicator(String chatId, bool isTyping) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('typing', {
        'chatId': chatId,
        'userId': _currentUserId,
        'isTyping': isTyping,
      });
    }
  }

  void markMessageAsDelivered(String messageId, String chatId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('mark_delivered', {
        'messageId': messageId,
        'chatId': chatId,
        'userId': _currentUserId,
      });
    }
  }

  void markMessageAsRead(String messageId, String chatId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('mark_read', {
        'messageId': messageId,
        'chatId': chatId,
        'userId': _currentUserId,
      });
    }
  }

  void markMessagesAsRead(List<String> messageIds, String chatId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('mark_messages_read', {
        'messageIds': messageIds,
        'chatId': chatId,
        'userId': _currentUserId,
      });
    }
  }

  void updateOnlineStatus(bool isOnline) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('update_status', {
        'userId': _currentUserId,
        'isOnline': isOnline,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  void disconnect() {
    if (_socket != null) {
      updateOnlineStatus(false);
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
    _typingController.close();
    _onlineUsersController.close();
  }
}
