import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ClockSection extends StatelessWidget {
  final String currentTime;

  const ClockSection({super.key, required this.currentTime});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
          style: GoogleFonts.rajdhani(color: Colors.black54),
        ),
        Text(
          currentTime,
          style: GoogleFonts.ramabhadra(
            fontSize: 55,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFB3202D),
            shadows: [
              Shadow(
                color: Colors.black54,
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
