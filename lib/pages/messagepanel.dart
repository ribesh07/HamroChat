// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';

class messagePage extends StatefulWidget {
  const messagePage({super.key});

  @override
  State<messagePage> createState() => _messagePageState();
}

class _messagePageState extends State<messagePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      backgroundColor: const Color(0xFF8A55DF),
      ),
      body: Container(
        alignment: Alignment.center,
        color: const Color(0xFF8A55DF),
        child: const Text('Message Page',style: TextStyle(color: Color(0xFFF9F8F9),fontSize: 20,fontWeight: FontWeight.bold),),
      ),
    );
  }
}