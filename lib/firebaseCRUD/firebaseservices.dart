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
  Stream<QuerySnapshot> getNotesStream(){
    // return notes.snapshots();
    final notesstream = notes.orderBy('timestamp',descending: true).snapshots();
    return notesstream;
  }

  //update
Future<void> updateNote(String id, String title, String description) async {
  return await notes
      .doc(id)
      .update({'title': title, 'description': description})
      .then((value) => debugPrint("Note Updated"))
      .catchError((error) => debugPrint("Failed to update note: $error"));
}
  //delete
  Future<void> deleteNote(String id) async {
    return await notes
        .doc(id)
        .delete()
        .then((value) => debugPrint("Note Deleted"))
        .catchError((error) => debugPrint("Failed to delete note: $error"));
}


}

