import 'package:dtr_app/components/my_button.dart';
import 'package:dtr_app/components/mytextfield.dart';
import 'package:dtr_app/components/swapping_tiles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void signInUser() async {
    final email = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showErrorMessage('Email and password are required.');
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      // Ensure FirebaseAuth is initialized
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Dismiss the loading dialog
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      // Navigate to home or trigger StreamBuilder
      widget.onTap?.call();
    } on FirebaseAuthException catch (e) {
      // Dismiss the loading dialog before showing error
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      showErrorMessage(e.message ?? 'Login failed. Please try again.');
    } catch (e, stackTrace) {
      // Log the error to get more details
      debugPrint("Unexpected error: $e");
      debugPrint("Error type: ${e.runtimeType}");
      debugPrint("Error message: ${e.toString()}");
      debugPrint("Stack trace: $stackTrace");

      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      showErrorMessage('Unexpected error: ${e.toString()}');
    }
  }

  // Error dialog
  void showErrorMessage(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFB3202D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Center(
            child: Text(
              'Email and password are required',
              style: GoogleFonts.rajdhani(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 5),
                Text(
                  'CHEFS HUT BAKERY CORPORATION',
                  style: GoogleFonts.aboreto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB3202D),
                    textStyle: TextStyle(
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: const Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const SwappingTiles(),
                const SizedBox(height: 10),
                Text(
                  "HAPPY DAY!   PLEASE SIGN IN",
                  style: GoogleFonts.rajdhani(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB3202D),
                  ),
                ),
                const SizedBox(height: 25), 
                MyTextField(
                  controller: _usernameController,
                  hintText: 'Email',
                  obscureText: false,
                ),
                const SizedBox(height: 5),
                MyTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 15),
                MyButton(text: "SIGN IN", onTap: signInUser),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
