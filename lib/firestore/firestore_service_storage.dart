import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseStorageService = Provider(
  (ref) => FirebaseStorageService(FirebaseStorage.instance
  ),
);
class FirebaseStorageService {
  final FirebaseStorage firebaseStorage;

  FirebaseStorageService(this.firebaseStorage);
  Future<String> uploadFileToFirebase(String ref, File file ) async {
    UploadTask uploadTask = firebaseStorage.ref().child(ref).putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUr = await snapshot.ref.getDownloadURL();
    return downloadUr;
  }


}
 
