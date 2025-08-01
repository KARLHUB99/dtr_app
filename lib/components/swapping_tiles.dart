
import 'package:dtr_app/components/square_tile.dart';
import 'package:flutter/material.dart';

class SwappingTiles extends StatefulWidget {
  const SwappingTiles({super.key});

  @override
  State<SwappingTiles> createState() => _SwappingTilesState();
}

class _SwappingTilesState extends State<SwappingTiles> {
  bool swapped = false;

  @override
  void initState() {
    super.initState();
    _startSwapLoop();
  }

  void _startSwapLoop() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 2));

      // Check if the widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          swapped = !swapped;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 150,
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            left: swapped ? 130 : 0,
            child: SquareTile(imagePath: 'lib/images/Panadero.png'),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            left: swapped ? 0 : 130,
            child: SquareTile(imagePath: 'lib/images/PDonuts.png'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Optionally, you can cancel ongoing tasks or timers here if needed
    super.dispose();
  }
}
