import 'package:flutter/material.dart';

class WavyHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    // Start slightly lower on the left edge
    path.lineTo(0, size.height * 0.85); 
    
    // Use a cubic curve for that perfect, shallow sweeping wave
    path.cubicTo(
      size.width * 0.35, size.height * 1.0,  // Control point 1: gently pulls down on the left-middle
      size.width * 0.70, size.height * 0.72, // Control point 2: gently pulls up on the right-middle
      size.width, size.height * 0.80         // End point: finishes smoothly on the right edge
    );
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
