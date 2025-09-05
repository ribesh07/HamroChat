enum MessageType {
  text,
  image,
  file,
  audio,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class MessageModel {
  final String messageId;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderPhotoURL;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final List<String> readBy; // For group chats
  final String? replyToMessageId;
  final String? fileURL;
  final String? fileName;
  final int? fileSize;
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoURL,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    this.deliveredAt,
    this.readAt,
    required this.readBy,
    this.replyToMessageId,
    this.fileURL,
    this.fileName,
    this.fileSize,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoURL': senderPhotoURL,
      'content': content,
      'type': type.index,
      'status': status.index,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'deliveredAt': deliveredAt?.millisecondsSinceEpoch,
      'readAt': readAt?.millisecondsSinceEpoch,
      'readBy': readBy,
      'replyToMessageId': replyToMessageId,
      'fileURL': fileURL,
      'fileName': fileName,
      'fileSize': fileSize,
      'metadata': metadata,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderPhotoURL: map['senderPhotoURL'],
      content: map['content'] ?? '',
      type: MessageType.values[map['type'] ?? 0],
      status: MessageStatus.values[map['status'] ?? 0],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      deliveredAt: map['deliveredAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deliveredAt'])
          : null,
      readAt: map['readAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['readAt'])
          : null,
      readBy: List<String>.from(map['readBy'] ?? []),
      replyToMessageId: map['replyToMessageId'],
      fileURL: map['fileURL'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      metadata: map['metadata'],
    );
  }

  MessageModel copyWith({
    String? messageId,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderPhotoURL,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    DateTime? deliveredAt,
    DateTime? readAt,
    List<String>? readBy,
    String? replyToMessageId,
    String? fileURL,
    String? fileName,
    int? fileSize,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoURL: senderPhotoURL ?? this.senderPhotoURL,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      readBy: readBy ?? this.readBy,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      fileURL: fileURL ?? this.fileURL,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      metadata: metadata ?? this.metadata,
    );
  }
}
