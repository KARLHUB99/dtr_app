import 'package:dtr_app/pages/login_or_register_page.dart';
import 'package:dtr_app/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Show loading indicator while waiting for the stream
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle errors in the stream
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'An error occurred. Please try again later.',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          // Check if the user is logged in
          if (snapshot.hasData && snapshot.data != null) {
            return const HomePage();
          }

          // If no user is logged in, show the login/register page
          return const LoginOrRegisterPage();
        },
      ),
    );
  }
}
