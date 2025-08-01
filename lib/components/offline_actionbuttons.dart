import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OfflineActionButtons extends StatelessWidget {
  final Function(String, Function(String), String) handleAction;
  final bool hasTimeIn;
  final bool hasLunchOut;
  final bool hasLunchIn;
  final bool hasTimeOut;

  const OfflineActionButtons({
    super.key,
    required this.handleAction,
    required this.hasTimeIn,
    required this.hasLunchOut,
    required this.hasLunchIn,
    required this.hasTimeOut,
  });

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    required bool isEnabled,
    required Color color,
  }) {
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
            onPressed: isEnabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnabled ? color : Colors.grey,
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
              elevation: 0,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActionButton(
          label: "TIME IN",
          onPressed: () => handleAction(
            "TIME IN",
            (time) {},
            "offline-time-in",
          ),
          isEnabled: !hasTimeIn,
          color: const Color(0xFF1E8449),
        ),
        _buildActionButton(
          label: "LUNCH OUT",
          onPressed: () => handleAction(
            "LUNCH OUT",
            (time) {},
            "offline-lunch-out",
          ),
          isEnabled: hasTimeIn && !hasLunchOut,
          color: const Color(0xFF4CAF50),
        ),
        _buildActionButton(
          label: "LUNCH IN",
          onPressed: () => handleAction(
            "LUNCH IN",
            (time) {},
            "offline-lunch-in",
          ),
          isEnabled: hasLunchOut && !hasLunchIn,
          color: const Color.fromARGB(255, 180, 140, 7),
        ),
        _buildActionButton(
          label: "TIME OUT",
          onPressed: () => handleAction(
            "TIME OUT",
            (time) {},
            "offline-time-out",
          ),
          isEnabled: hasLunchIn && !hasTimeOut,
          color: const Color(0xFFB3202D),
        ),
      ],
    );
  }
}
