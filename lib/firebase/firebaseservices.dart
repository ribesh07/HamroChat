import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
class Firebaseservice{
  //get connection
  final CollectionReference notes = FirebaseFirestore.instance.collection('notes');


  //create data
  Future<void> addnote(String title,String description) {
    return notes
        .add({'title': title, 
        'description': description,
        'timestamp': Timestamp.now()
        })
        .then((value) => debugPrint("Note Added"))
        .catchError((error) => debugPrint("Failed to add note: $error"));
  }


  //read data

  //update

  //delete


}