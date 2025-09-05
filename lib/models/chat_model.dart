enum ChatType {
  oneOnOne,
  group,
}

class ChatModel {
  final String chatId;
  final String chatName;
  final String? chatImage;
  final ChatType type;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final List<String> admins; // For group chats
  final Map<String, int> unreadCount; // userId -> count
  final bool isActive;
  final String? description;
  final Map<String, dynamic>? settings;

  ChatModel({
    required this.chatId,
    required this.chatName,
    this.chatImage,
    required this.type,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.admins,
    required this.unreadCount,
    required this.isActive,
    this.description,
    this.settings,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'chatName': chatName,
      'chatImage': chatImage,
      'type': type.index,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
      'lastMessageSenderId': lastMessageSenderId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'admins': admins,
      'unreadCount': unreadCount,
      'isActive': isActive,
      'description': description,
      'settings': settings,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      chatId: map['chatId'] ?? '',
      chatName: map['chatName'] ?? '',
      chatImage: map['chatImage'],
      type: ChatType.values[map['type'] ?? 0],
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'])
          : null,
      lastMessageSenderId: map['lastMessageSenderId'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      createdBy: map['createdBy'] ?? '',
      admins: List<String>.from(map['admins'] ?? []),
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      isActive: map['isActive'] ?? true,
      description: map['description'],
      settings: map['settings'],
    );
  }

  ChatModel copyWith({
    String? chatId,
    String? chatName,
    String? chatImage,
    ChatType? type,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    List<String>? admins,
    Map<String, int>? unreadCount,
    bool? isActive,
    String? description,
    Map<String, dynamic>? settings,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      chatName: chatName ?? this.chatName,
      chatImage: chatImage ?? this.chatImage,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      admins: admins ?? this.admins,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      settings: settings ?? this.settings,
    );
  }

  // Helper methods
  String getDisplayName(String currentUserId) {
    if (type == ChatType.group) {
      return chatName;
    } else {
      // For one-on-one chats, return the other participant's name
      // This would typically be resolved with user data
      return chatName;
    }
  }

  String? getDisplayImage(String currentUserId) {
    if (type == ChatType.group) {
      return chatImage;
    } else {
      // For one-on-one chats, return the other participant's image
      return chatImage;
    }
  }

  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  bool isAdmin(String userId) {
    return admins.contains(userId);
  }

  bool hasParticipant(String userId) {
    return participants.contains(userId);
  }
}
