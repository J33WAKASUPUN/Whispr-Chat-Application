import 'package:flutter/material.dart';
import 'package:whispr_chat_app/services/auth/auth_service.dart';
import 'package:whispr_chat_app/components/my_button.dart';
import 'package:whispr_chat_app/components/my_textField.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool isLoading = false;

  // reset password method
  Future<void> resetPassword() async {
    setState(() {
      isLoading = true;
    });

    try {
      await AuthService().resetPassword(_emailController.text.trim());

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Password Reset Email Sent'),
            content: Text('Please check your email to reset your password.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to login page
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.secondary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [

            SizedBox(height: 70),
            
            // Logo
            Center(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.lock_reset_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            SizedBox(height: 60),

            // Title
            Text(
              'Reset Password',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 8),
            Text(
              'Enter your email address to receive a password reset link',
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            SizedBox(height: 40),

            // Email field
            MyTextField(
              hintText: "Email",
              obscureText: false,
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
            ),

            SizedBox(height: 24),

            // Reset button
            isLoading
                ? Center(child: CircularProgressIndicator())
                : MyButton(
                    text: 'Send Reset Link',
                    onTap: resetPassword,
                  ),
          ],
        ),
      ),
    );
  }
}
