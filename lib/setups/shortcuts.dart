// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ImagePicker _picker = ImagePicker();


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
