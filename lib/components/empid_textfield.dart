import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IDTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final void Function(String)
  onChanged; // Use onChanged as a function parameter

  const IDTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.onChanged, // Pass onChanged here
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0), // Less restrictive
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: TextInputType.numberWithOptions(),
          textAlign: TextAlign.center,
          style: GoogleFonts.rajdhani(
            fontSize: 33,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 15, 6, 7),
          ),
          cursorColor: const Color(0xFFDA1A29),
          onChanged: onChanged, // Attach the onChanged callback
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.grey.shade200,
            contentPadding: const EdgeInsets.symmetric(vertical: 5.0),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(70),
              borderSide: const BorderSide(
                color: Color(0xFFDA1A29),
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
