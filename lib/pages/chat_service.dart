import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final CollectionReference chatCollection = FirebaseFirestore.instance.collection('chats');

  Future<void> sendMessage(String chatId, String userId, String message) async {
    await chatCollection.doc(chatId).collection('messages').add({
      'userId': userId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return chatCollection.doc(chatId).collection('messages').orderBy('timestamp').snapshots();
  }
}