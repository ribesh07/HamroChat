// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hamrochat/login/input_field.dart';
import 'package:hamrochat/setups/provider.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final emailcontroller = TextEditingController();
  final provider = settingProvider();
  final formkey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _sendPasswordResetEmail() async {
    try {
      // await _auth.sendPasswordResetEmail(email: emailcontroller.text);
      FirebaseAuth.instance.sendPasswordResetEmail(email: emailcontroller.text);
      // FirebaseAuth.
      print("Inside Logic");
      print(emailcontroller.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent')),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      if (e.code == 'user-not-found') {
        print(e.code);
        message = 'No user found for that email.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Password'),
        centerTitle: true,
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        color: Colors.blue,
        child: Form(
          key: formkey,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  height: 50,
                ),
                Text(
                  "Provide Your Registered Email",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 10,
                    child: InputField(
                      label: "Email",
                      icon: Icons.mail,
                      controller: emailcontroller,
                      validator: (value) => provider.emailValidator(value),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                    onPressed: () {
                      if (formkey.currentState!.validate()) {
                        print(emailcontroller);
                        print("submit invoked !!!");
                        _sendPasswordResetEmail();
                      } else {}
                    },
                    child: Text(
                      "Submit",
                      style: TextStyle(
                          color: const Color.fromARGB(255, 18, 9, 44)),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
