import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NameTextField extends StatelessWidget {
  final TextEditingController controller;

  const NameTextField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          readOnly: true,
          textAlign: TextAlign.center,
          style: GoogleFonts.rajdhani(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            labelText: 'EMPLOYEE NAME',
            labelStyle: GoogleFonts.rajdhani(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            filled: true,
            fillColor: Colors.grey.shade200,
            //prefixIcon: Icon(Icons.person, color: Colors.black),
            contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Color(0xFFDA1A29), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.black, width: 2.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.black, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
