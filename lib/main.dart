// ignore_for_file: unused_import, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hamrochat/color-collection.dart';
import 'package:hamrochat/firebaseCRUD/home.dart';
import 'package:hamrochat/firebaseCRUD/readdata.dart';
import 'package:hamrochat/login/login_screen.dart';
import 'package:hamrochat/pages/Chat.dart';
import 'package:hamrochat/routes.dart';
import 'firebase_options.dart';
// import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hamro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF8A55DF)),
        useMaterial3: true,
      ),
      onGenerateRoute: (settings) => generateRoute(settings),
      home:
          // readData(),
          // Homepage(),
          // const MyHomePage(title: 'HamroChat'),
          StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          if (snapshot.hasData) {
            final FirebaseAuth auth = FirebaseAuth.instance;
            User? user = auth.currentUser;

            return MyHomePage(
              title: 'Hamro',
              email: user!.email,
              uid: user.uid,
            ); // Create a HomeScreen widget
          }
          return Login_page();
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  // final uid;
  String? uid;
  String? email;
  MyHomePage({super.key, required this.title, this.uid, this.email});
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
                'Welcome to ${widget.title} : ${widget.email}',
                style: TextStyle(color: Color(0xFF9C07E6)),
              ),
              SizedBox(height: 30),
              Text(
                'USER UID : ${widget.uid}',
                style: TextStyle(color: Color(0xFF9C07E6)),
              ),
              SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ElevatedButton(
                  onPressed: () {
                    pathtoLoginpage(context);
                  },
                  child: Text(
                    'Continue >>',
                    style: textStyle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ElevatedButton(
                  onPressed: () {
                    // Navigator.of(context).pushNamed('/chatscreen');
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(uid:widget.uid)));
                  },
                  child: Text(
                    'Chat Screen',
                    style: textStyle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ElevatedButton(
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    // String uuid = FirebaseAuth.instance.currentUser.uid;
                    // String eemail = userCredential.user?.email;
                    // print(uuid);

                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => Login_page()));
                  },
                  child: Text(
                    'Logout',
                    style: textStyle,
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
