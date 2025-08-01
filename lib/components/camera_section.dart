import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraSection extends StatelessWidget {
  final bool isCameraInitialized;
  final CameraController? controller;

  const CameraSection({
    super.key,
    required this.isCameraInitialized,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          isCameraInitialized && controller != null
              ? Transform(
                alignment: Alignment.center,
                // Flip horizontally only if front camera
                transform:
                    controller!.description.lensDirection ==
                            CameraLensDirection.front
                        ? Matrix4.rotationY(
                          3.14159,
                        ) // pi radians = 180 degrees flip
                        : Matrix4.identity(),
                child: CameraPreview(controller!),
              )
              : Container(
                color: Colors.black,
                child: const Center(
                  child: Icon(
                    Icons.camera_alt,
                    size: 80,
                    color: Colors.white70,
                  ),
                ),
              ),

          Positioned(
            top: 20,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, size: 32, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pop(); // Or your custom close logic
              },
            ),
          ),
        ],
      ),
    );
  }
}
