import 'package:flutter/material.dart';

class UserSection extends StatelessWidget {
  const UserSection({super.key});

  Widget _buildLogo(String path) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,  // Set the background color to white
        shape: BoxShape.circle,
        image: DecorationImage(image: AssetImage(path), fit: BoxFit.cover),
        border: Border.all(color: Colors.redAccent, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLogo('lib/images/Panadero.png'),
        const SizedBox(width: 10),
        _buildLogo('lib/images/PDonuts.png'),
      ],
    );
  }
}
