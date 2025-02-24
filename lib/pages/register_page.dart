import 'package:flutter/material.dart';
import 'package:whispr_chat_app/services/auth/auth_service.dart';
import 'package:whispr_chat_app/components/my_button.dart';
import 'package:whispr_chat_app/components/my_textField.dart';

class RegisterPage extends StatelessWidget {
  // text controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // tap go to the signin page
  final void Function()? onTap;

  RegisterPage({super.key, required this.onTap});

  // register method
  void register(BuildContext context) async {
    final auth = AuthService();
    if (_passwordController.text == _confirmPasswordController.text) {
      try {
        auth.signUpWithEmailPassword(
          _emailController.text,
          _passwordController.text,
          _usernameController.text,

        );
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(e.toString()),
          ),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Passwords do not match"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // // Back button
                // IconButton(
                //   icon: Icon(
                //     Icons.arrow_back,
                //     color: Theme.of(context).colorScheme.secondary,
                //   ),
                //   onPressed: () => Navigator.pop(context),
                // ),

                SizedBox(height: 45),

                // Logo
                Center(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.chat_bubble_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),

                SizedBox(height: 40),

                // Welcome text
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: 8),
                Text(
                  'Fill in your details to get started',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),

                SizedBox(height: 32),

                // Username field
                MyTextField(
                  hintText: "Username",
                  obscureText: false,
                  controller: _usernameController,
                  prefixIcon: Icons.person_outline,
                ),

                SizedBox(height: 16),

                // Email field
                MyTextField(
                  hintText: "Email",
                  obscureText: false,
                  controller: _emailController,
                  prefixIcon: Icons.email_outlined,
                ),

                SizedBox(height: 16),

                // Password field
                MyTextField(
                  hintText: "Password",
                  obscureText: true,
                  controller: _passwordController,
                  prefixIcon: Icons.lock_outline,
                ),

                SizedBox(height: 16),

                // Confirm password field
                MyTextField(
                  hintText: "Confirm Password",
                  obscureText: true,
                  controller: _confirmPasswordController,
                  prefixIcon: Icons.lock_outline,
                ),

                SizedBox(height: 32),

                // Register button
                MyButton(
                  text: 'Create Account',
                  onTap: () => register(context),
                ),

                SizedBox(height: 24),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary),
                    ),
                    TextButton(
                      onPressed: onTap,
                      child: Text(
                        "Sign In",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
