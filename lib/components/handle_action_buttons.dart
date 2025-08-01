import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionButtons extends StatelessWidget {
  final Function(String, Function(String), String) handleAction;
  final VoidCallback onViewAttendanceLog;
  final bool hasTimeIn; // True if employee has Time In
  final bool hasLunchOut; // True if employee has Lunch Out
  final bool hasLunchIn; // True if employee has Lunch In
  final bool hasTimeOut; // True if employee has Time Out
  final bool hasAttendanceData; // True if there is any attendance data
  final List<dynamic>
  apiResponse; // API response to check for empty or valid data

  const ActionButtons({
    super.key,
    required this.handleAction,
    required this.onViewAttendanceLog,
    required this.hasTimeIn,
    required this.hasLunchOut,
    required this.hasLunchIn,
    required this.hasTimeOut,
    required this.hasAttendanceData, // New parameter to check if data exists
    required this.apiResponse, // API response passed as a parameter
  });

  Widget _buildActionButton(String label, VoidCallback onPressed, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                offset: const Offset(1, 3),
                blurRadius: 5,
              ),
            ],
            borderRadius: BorderRadius.circular(14),
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: GoogleFonts.rajdhani(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              elevation: 0, // Keep this 0 to avoid double shadow
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If no attendance data is available, return an empty container (no buttons)
    if (!hasAttendanceData || apiResponse.isEmpty ) {
      // If the response is empty or no attendance data, show "TIME IN"
      return _buildActionButton(
        "TIME IN",
        () => handleAction(
          "TIME IN",
          (time) {},
          'http://panaderooffice.ddns.net:8080/DTRApi/api/time_in.php',
        ),
        const Color(0xFF1E8449),
      );
    }

    return Column(
      children: [
        if (!hasTimeIn)
          _buildActionButton(
            "TIME IN",
            () => handleAction(
              "TIME IN",
              (time) {},
              'http://panaderooffice.ddns.net:8080/DTRApi/api/time_in.php',
            ),
            const Color(0xFF1E8449),
          ),

        if (hasTimeIn && !hasLunchOut)
          _buildActionButton(
            "LUNCH OUT",
            () => handleAction(
              "LUNCH OUT",
              (time) {},
              'http://panaderooffice.ddns.net:8080/DTRApi/api/lunch_out.php',
            ),
            const Color(0xFF4CAF50),
          ),

        if (hasTimeIn && hasLunchOut && !hasLunchIn)
          _buildActionButton(
            "LUNCH IN",
            () => handleAction(
              "LUNCH IN",
              (time) {},
              'http://panaderooffice.ddns.net:8080/DTRApi/api/lunch_in.php',
            ),
            const Color.fromARGB(255, 180, 140, 7),
          ),

        if (hasTimeIn && hasLunchOut && hasLunchIn && !hasTimeOut)
          _buildActionButton(
            "TIME OUT",
            () => handleAction(
              "TIME OUT",
              (time) {},
              'http://panaderooffice.ddns.net:8080/DTRApi/api/time_update.php',
            ),
            const Color(0xFFB3202D),
          ),
      ],
    );
  }
}
