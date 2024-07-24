import 'package:flutter/material.dart';
import 'package:hamrochat/login/SIgnup_page.dart';
import 'package:hamrochat/login/login_screen.dart';
import 'package:hamrochat/main.dart';
// import 'package:hamrochat/pages/login.dart';
// import 'package:hamrochat/pages/signup.dart';
import 'package:hamrochat/pages/Chat.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/login':
      return MaterialPageRoute(builder: (context) => Login_page());

    case '/signup':
      return MaterialPageRoute(builder: (context) => Signup_page());
    case '/chatscreen':
      return MaterialPageRoute(builder: (context) => ChatScreen());

    default:
      return MaterialPageRoute(
          builder: (context) => MyHomePage(
                title: 'HamroChat',
                // uid: '',
              ));
  }
}
