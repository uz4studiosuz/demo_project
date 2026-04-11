import 'package:flutter/material.dart';
import '../additional/painters.dart';

class LiquidBackground extends StatelessWidget {
  final List<Color> gradientColors;
  final Color waveColor;

  const LiquidBackground({
    super.key,
    this.gradientColors = const [
      Color(0xFF004CC5),
      Color(0xFF4364F7),
      Color(0xFF6FB1FC),
    ],
    this.waveColor = const Color(0x14FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: LiquidPainter(
              color: waveColor,
            ),
          ),
        ),
      ],
    );
  }
}
