import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import 'control_button.dart';

class RightSideButtons extends StatelessWidget {
  final bool isNavigationStarted;
  final String distance;
  final double currentSpeed;
  final double displayMapRotation;
  final String mapLayer;
  final bool followUser;
  final VoidCallback onCompassTap;
  final VoidCallback onLayerTap;
  final VoidCallback onFocusUserTap;
  final VoidCallback onSoundTap;

  const RightSideButtons({
    super.key,
    required this.isNavigationStarted,
    required this.distance,
    required this.currentSpeed,
    required this.displayMapRotation,
    required this.mapLayer,
    required this.followUser,
    required this.onCompassTap,
    required this.onLayerTap,
    required this.onFocusUserTap,
    required this.onSoundTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: isNavigationStarted ? 90 : (distance.isNotEmpty ? 155 : 80),
      right: 12,
      child: Column(
        children: [
          // Tezlik o'lchagich (Speedometer)
          if (isNavigationStarted)
            Container(
              width: 46,
              height: 46,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      (currentSpeed * 3.6).round().toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.0,
                        color: Colors.black87,
                      ),
                    ),
                    const Text(
                      'km/h',
                      style: TextStyle(
                        fontSize: 9,
                        height: 1.0,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Kompas
          if (isNavigationStarted)
            MapControlButton(
              heroTag: 'compass_btn',
              icon: Transform.rotate(
                angle: displayMapRotation * math.pi / 180,
                child: const Icon(
                  Icons.navigation,
                  color: Colors.red,
                  size: 22,
                ),
              ),
              onTap: onCompassTap,
            ),
          if (isNavigationStarted) const SizedBox(height: 10),

          // Qatlam
          MapControlButton(
            heroTag: 'layer_toggle',
            icon: Icon(
              mapLayer == 'm'
                  ? Icons.layers
                  : (mapLayer == 'y' ? Icons.layers_outlined : Icons.satellite_alt),
              color: Colors.black87,
              size: 22,
            ),
            onTap: onLayerTap,
          ),
          const SizedBox(height: 10),

          // Fokus
          MapControlButton(
            heroTag: 'focus_user',
            icon: Icon(
              Icons.my_location,
              color: followUser ? AppColors.primary : Colors.black54,
              size: 22,
            ),
            onTap: onFocusUserTap,
          ),

          if (isNavigationStarted) ...[
            const SizedBox(height: 10),
            // Ovoz (placeholder)
            MapControlButton(
              heroTag: 'sound_btn',
              icon: const Icon(
                Icons.volume_up,
                color: Colors.black87,
                size: 22,
              ),
              onTap: onSoundTap,
            ),
          ],
        ],
      ),
    );
  }
}