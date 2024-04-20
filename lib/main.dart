import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:hamrochat/firebaseconfig.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  if(kIsWeb){
  await Firebase.initializeApp(
    options:const FirebaseOptions(apiKey: Firebaseonfigg_data.apikey,
      authDomain: Firebaseonfigg_data.authDomain,
      projectId: Firebaseonfigg_data.projectId,
      storageBucket: Firebaseonfigg_data.storageBucket,
      messagingSenderId: Firebaseonfigg_data.messagingSenderId,
      appId: Firebaseonfigg_data.appId,measurementId: Firebaseonfigg_data.measurementId),
    );
  }else{
    await Firebase.initializeApp();
  }
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hamro Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'HamroChat'),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title:
            Container(alignment: Alignment.center, child: Text(widget.title)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Text(widget.title),
            Text('Welcome to ${widget.title}'),
          ],
        ),
      ),
    );
  }
}
