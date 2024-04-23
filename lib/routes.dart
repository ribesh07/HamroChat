import 'package:flutter/material.dart';
import 'package:hamrochat/main.dart';
import 'package:hamrochat/pages/login.dart';
import 'package:hamrochat/pages/signup.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/login':
      return MaterialPageRoute(builder: (context) => Login_page());

    case '/signup':
      return MaterialPageRoute(builder: (context) => Signup_page());

    default:
      return MaterialPageRoute(builder: (context) => const MyHomePage(title: 'HamroChat',));
  }
}
