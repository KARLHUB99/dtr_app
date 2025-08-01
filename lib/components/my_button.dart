import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyButton extends StatelessWidget {
  final Function()? onTap;
  final String text;

  const MyButton({super.key, required this.onTap, required this.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFB3202D),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.rajdhani(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              textStyle: TextStyle(
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    offset: const Offset(1, 1),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
