// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import 'package:provider/provider.dart';
// import 'chat_service.dart';

// class ChatScreen extends StatefulWidget {
//   final String chatId;

//   ChatScreen({required this.chatId});

//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _controller = TextEditingController();
//   late ChatService _chatService;

//   @override
//   void initState() {
//     super.initState();
//     _chatService = ChatService();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final user = Provider.of<User?>(context);

//     return Scaffold(
//       appBar: AppBar(title: Text("Chat")),
//       body: Column(
//         children: <Widget>[
//           Expanded(
//             child: StreamBuilder(
//               stream: _chatService.getMessages(widget.chatId),
//               builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
//                 if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

//                 return ListView(
//                   children: snapshot.data!.docs.map((doc) {
//                     return ListTile(
//                       title: Text(doc['message']),
//                       subtitle: Text(doc['userId'] == user?.uid ? "Me" : "Other"),
//                     );
//                   }).toList(),
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: <Widget>[
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: InputDecoration(hintText: "Enter message..."),
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.send),
//                   onPressed: () {
//                     if (_controller.text.isNotEmpty) {
//                       _chatService.sendMessage(widget.chatId, user!.uid, _controller.text);
//                       _controller.clear();
//                     }
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
