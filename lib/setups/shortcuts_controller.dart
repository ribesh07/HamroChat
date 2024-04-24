// ignore_for_file: non_constant_identifier_names, prefer_typing_uninitialized_variables, use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// import 'package:flutter/foundation.dart';
import 'package:hamrochat/firestore/firestore_service_storage.dart';
import 'package:hamrochat/models/user_model.dart';
import 'package:hamrochat/pages/messagepanel.dart';
import 'package:image_picker/image_picker.dart';

// ImagePicker _picker = ImagePicker();

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  ),
);

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  AuthRepository({
    required this.auth,
    required this.firestore,
  });

  Future<User_model?> getCurrentUserData() async {
    var userData =
        await firestore.collection('users').doc(auth.currentUser?.uid).get();

    User_model? user;
    if (userData.data() != null) {
      user = User_model.fromMap(userData.data()!);
    }
    return user;
  }

  // void signInWithPhone(BuildContext context, String phoneNumber) {}


  void saveUserDataToFirebase({
  required BuildContext context,
  required String name,
  required String email,
  required String password,
  required File? profilepic,
  required ProviderRef ref,
}) async {
  try {
    await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String photourl = '';

    if (profilepic != null) {
      // String profilePicUrl = await uploadFileToFirebase('profilePic', profilepic);
      photourl = await ref
          .read(firebaseStorageService)
          .uploadFileToFirebase('profilePic/$uid', profilepic);
    }
    var user = User_model(
      name: email.split('@')[0],
      email: email,
      uid: uid,
      profileimage: photourl,
      groupId: [],
      Isonline: true,
    );
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(user.toMap());
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const messagePage()),
        (route) => false);
  } catch (e) {
    debugPrint(e.toString());
  }
}

    Stream<User_model> userData(String userId) {
    return firestore.collection('users').doc(userId).snapshots().map(
          (event) => User_model.fromMap(
            event.data()!,
          ),
        );
  }

  void setUserState(bool isOnline) async {
    await firestore.collection('users').doc(auth.currentUser!.uid).update({
      'isOnline': isOnline,
    });
  }

}

Future<File?> PickImageFromGallery(BuildContext contex) async {
  File? image;
  try {
    final Pickimage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (Pickimage != null) {
      image = File(Pickimage.path);
    }
  } catch (e) {
    debugPrint(e.toString());
  }
  return image;
}




