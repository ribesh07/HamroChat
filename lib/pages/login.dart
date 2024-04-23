import 'package:flutter/material.dart';

class Login_page extends StatefulWidget {
  const Login_page({Key? key}) : super(key: key);

  
  @override
  State<Login_page> createState() => _Login_pageState();
}

// ignore: camel_case_types
class _Login_pageState extends State<Login_page> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        color: Colors.blueGrey[100],

        child: Column(
          children: [
            Text('Login Page',
              style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
