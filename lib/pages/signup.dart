// // ignore_for_file: camel_case_types

// import 'dart:io';
// // import 'dart:js';

// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:hamrochat/color-collection.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hamrochat/setups/auth_controller.dart';
// import 'package:hamrochat/setups/shortcuts_controller.dart';

// class Signup_page extends ConsumerStatefulWidget {
//   const Signup_page({super.key});

//   @override
//   ConsumerState<Signup_page> createState() => _Signup_pageState();
// }

// class _Signup_pageState extends ConsumerState<Signup_page> {
//   final emailcontroller = TextEditingController();
//   final passcontroller = TextEditingController();
//   final cpasscontroller = TextEditingController();
//   File? image;
//   void selectImage() async {
//     image = await PickImageFromGallery(context);
//     setState(() {});
//   }

//   void storeUserData() async {
//     String email = emailcontroller.text.trim();
//     String name = email.split('@')[0];
//     String password = passcontroller.text.trim();
//     String cpassword = cpasscontroller.text.trim();

//     if (image != null) {
//       if (password == cpassword) {
//         if (email.isNotEmpty && password.isNotEmpty) {
//           ref
//               .read(authControllerProvider)
//               .saveUserDataToFirebase(context, name, email, password, image);
//         }
//       }
//     }
//   }

//   @override
//   void dispose() {
//     emailcontroller.dispose();
//     passcontroller.dispose();
//     cpasscontroller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Container(
//             alignment: Alignment.center,
//             child: const Text(
//               'SignUp Page',
//               style: textStyleappbar,
//             )),
//         backgroundColor: appbarcolor,
//       ),
//       body: SingleChildScrollView(
//         child: SafeArea(
//           child: Container(
//             width: double.infinity,
//             height: MediaQuery.of(context).size.height,
//             alignment: Alignment.center,
//             color: Colors.blueGrey[100],
//             child: Column(
//               children: [
//                 const SizedBox(
//                   height: 40,
//                 ),
//                 Stack(
//                   children: [
//                     image != null
//                         ? CircleAvatar(
//                             backgroundImage: FileImage(image!),
//                             radius: 46,
//                             // child: Icon(
//                             //   Icons.person,
//                             //   size: 50,
//                             // )
//                           )
//                         : CircleAvatar(
//                             backgroundColor: appbarcolor,
//                             radius: 46,
//                             child: GestureDetector(
//                               onTap: selectImage,
//                               child: const Icon(
//                                 Icons.person,
//                                 size: 50,
//                               ),
//                             ),
//                           ),
//                     if (image == null)
//                       Positioned(
//                         bottom: -6,
//                         right: -10,
//                         child: IconButton(
//                           onPressed: () {
//                             selectImage();
//                           },
//                           icon: const Icon(
//                             Icons.add_a_photo_outlined,
//                             size: 30,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(
//                   height: 26,
//                 ),
//                 image == null
//                     ? const Text(
//                         'Add Image',
//                         style: textStyle,
//                       )
//                     : const Text(
//                         'Your Image',
//                         style: textStyle,
//                       ),
//                 const SizedBox(
//                   height: 20,
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.only(
//                       top: 8, bottom: 10, left: 18, right: 18),
//                   child: TextField(
//                     controller: emailcontroller,
//                     decoration: const InputDecoration(
//                       labelText: 'Email',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//                 // const SizedBox(height: 20,),
//                 Padding(
//                   padding: const EdgeInsets.only(
//                       top: 5, bottom: 10, left: 18, right: 18),
//                   child: TextField(
//                     controller: passcontroller,
//                     obscureText: true,
//                     decoration: const InputDecoration(
//                       labelText: 'Password',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.only(
//                       top: 5, bottom: 10, left: 18, right: 18),
//                   child: TextField(
//                     controller: cpasscontroller,
//                     obscureText: true,
//                     decoration: const InputDecoration(
//                       labelText: 'Confirm Password',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//                 //    const SizedBox(height: 10,),
//                 //   const Row(
//                 //   mainAxisAlignment: MainAxisAlignment.center,
//                 //   crossAxisAlignment: CrossAxisAlignment.center,
//                 //   children: [
//                 //     Text('Don\'t have an account ??',style: textStyle,),
//                 //     Text('  SignUp',style:TextStyle(color: Color.fromARGB(255, 154, 60, 227),fontWeight: FontWeight.w600,fontSize: 20),),
//                 //   ],
//                 // ),
//                 Padding(
//                   padding: const EdgeInsets.only(top: 30),
//                   child: ElevatedButton(
//                     onPressed: () {
//                       debugPrint(emailcontroller.text);
//                       debugPrint(passcontroller.text);
//                       debugPrint(cpasscontroller.text);
//                       storeUserData();
//                       setState(() {
//                         if (passcontroller.text == cpasscontroller.text) {
//                           debugPrint('password matched');
//                         } else {
//                           debugPrint('password not matched');
//                         }
//                       });
//                     },
//                     child: const Text(
//                       'Submit',
//                       style: textStyle,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
