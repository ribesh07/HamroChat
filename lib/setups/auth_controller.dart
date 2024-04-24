
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hamrochat/models/user_model.dart';
import 'package:hamrochat/setups/shortcuts_controller.dart';

final authControllerProvider = Provider((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository: authRepository, ref: ref);
});

final userDataAuthProvider = FutureProvider((ref) {
  final authController = ref.watch(authControllerProvider);
  return authController.getUserData();
});

class AuthController {
  final AuthRepository authRepository;
  final ProviderRef ref;
  AuthController({
    required this.authRepository,
    required this.ref,
  });

  Future<User_model?> getUserData() async {
    User_model? user = await authRepository.getCurrentUserData();
    return user;
  }

  void saveUserDataToFirebase(
      BuildContext context,String name , String email, String password,File? profilePic) {
    authRepository.saveUserDataToFirebase(
      name:name,
      email: email,
      password: password,
      profilepic: profilePic,
      context: context,
      ref: ref,
    );
  }

  Stream<User_model> userDataById(String userId) {
    return authRepository.userData(userId);
  }

  void setUserState(bool isOnline) {
    authRepository.setUserState(isOnline);
  }
}