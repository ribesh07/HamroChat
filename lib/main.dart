// ignore_for_file: unused_import, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hamrochat/color-collection.dart';
import 'package:hamrochat/firebaseCRUD/home.dart';
import 'package:hamrochat/firebaseCRUD/readdata.dart';
import 'package:hamrochat/routes.dart';
import 'firebase_options.dart';
// import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HamroChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF8A55DF)),
        useMaterial3: true,
      ),
      onGenerateRoute: (settings) => generateRoute(settings),
      home:
          // readData(),
          // Homepage(),
          const MyHomePage(title: 'HamroChat'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void pathtoLoginpage(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF8A55DF),
        // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Container(
            alignment: Alignment.center,
            child: Text(
              widget.title,
              style: TextStyle(
                  color: Color(0xFFF9F8F9),
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            )),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            // begin: Alignment.topCenter,
            // end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF9FAFB),
              Color.fromARGB(255, 244, 246, 249),
              // Color(0xffe6e9f0),Color(0xffe6e9f0),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Text(widget.title),
              Text(
                'Welcome to ${widget.title}',
                style: TextStyle(color: Color(0xFF9C07E6)),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ElevatedButton(onPressed: () {
                  pathtoLoginpage(context);
                }, child: Text('Continue >>',style: textStyle,
                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
