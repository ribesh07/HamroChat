// ignore_for_file: camel_case_types, prefer_const_constructors

// import 'dart:js_interop';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hamrochat/login/Forgot_password.dart';
import 'package:hamrochat/login/SIgnup_page.dart';
// import 'package:hamrochat/login/SIgnup_page.dart';

import 'package:hamrochat/login/input_field.dart';
import 'package:hamrochat/main.dart';
// import 'package:hamrochat/pages/signup.dart';
import 'package:hamrochat/setups/provider.dart';

class Login_page extends StatefulWidget {
  const Login_page({super.key});

  @override
  State<Login_page> createState() => _Login_pageState();
}

class _Login_pageState extends State<Login_page> {
  bool passObsecure = true;
  final provider = settingProvider();
  final formkey = GlobalKey<FormState>();
  final emailcontroller = TextEditingController();
  final passcontroller = TextEditingController();
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    emailcontroller.dispose();
    passcontroller.dispose();
    // cpasscontroller.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailcontroller.text,
        password: passcontroller.text,
      );
      print("User logged in: ${userCredential.user?.email}");
      // String temp = userCredential.user?.email as String;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  MyHomePage(title: 'logged in ',uid:userCredential.user?.uid ,email: userCredential.user?.email,)));
      // Navigate to home screen or do something else
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
            alignment: Alignment.center,
            child: const Padding(
              padding: EdgeInsets.only(right: 69),
              child: Text(
                'Login Page',
              ),
            )),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: double.infinity,
        child: Form(
          key: formkey,
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height,
              alignment: Alignment.center,
              color: Color.fromARGB(255, 255, 255, 255),
              child: Column(
                children: [
                  const SizedBox(
                    height: 40,
                  ),
                  const CircleAvatar(
                    radius: 46,
                    child: Icon(
                      Icons.person,
                      size: 50,
                    ),
                  ),
                  const SizedBox(
                    height: 26,
                  ),
                  const Text(
                    'Your Creditinals',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 8, bottom: 10, left: 18, right: 18),
                    child: InputField(
                      label: "Email",
                      icon: Icons.mail,
                      controller: emailcontroller,
                      validator: (value) => provider.emailValidator(value),
                    ),
                  ),
                  // const SizedBox(height: 20,),
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 5, bottom: 10, left: 18, right: 18),
                    child: InputField(
                      label: 'Password',
                      icon: Icons.lock,
                      controller: passcontroller,
                      isvisible: passObsecure,
                      eyeButton: IconButton(
                        onPressed: () {
                          setState(() {
                            passObsecure = !passObsecure;
                          });
                        },
                        icon: Icon(passObsecure
                            ? Icons.visibility_off
                            : Icons.visibility),
                      ),
                      inputFormat: [LengthLimitingTextInputFormatter(16)],
                      validator: (value) => provider.passwordValidator(value),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("Don't have an account ??",
                          style: TextStyle(color: Colors.black, fontSize: 20)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Signup_page()));
                        },
                        child: const Text(
                          '  SignUp',
                          style: TextStyle(
                              color: Color.fromARGB(255, 154, 60, 227),
                              fontWeight: FontWeight.w600,
                              fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ForgotPassword()));
                      },
                      child: Text("Forgot Password ??")),
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: ElevatedButton(
                      onPressed: () {
                        if (formkey.currentState!.validate()) {
                          //logic

                          _login();
                        } else {}
                        debugPrint(emailcontroller.text);
                        debugPrint(passcontroller.text);
                      },
                      child: const Text(
                        'Submit',
                        style: TextStyle(
                            color: Color.fromARGB(255, 154, 60, 227),
                            fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
