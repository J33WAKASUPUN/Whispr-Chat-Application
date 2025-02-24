import 'package:flutter/material.dart';
import 'package:whispr_chat_app/pages/login_page.dart';
import 'package:whispr_chat_app/pages/register_page.dart';

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {

  // initially show login page
  bool showLoginPage = true;

  // toggle between login and register pages
  void toggleLoginRegister() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(
        onTap: toggleLoginRegister,
      );
    } else {
      return RegisterPage(
        onTap: toggleLoginRegister,
      );
    }
  }
}