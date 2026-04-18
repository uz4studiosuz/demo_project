import 'package:flutter/material.dart';

class GoogleNavBottomBar extends StatelessWidget {
  final String duration;
  final String distance;
  final VoidCallback onStopNavigation;
  final VoidCallback onShowExternalMaps;
  final VoidCallback onCenterOnRoute;

  const GoogleNavBottomBar({
    super.key,
    required this.duration,
    required this.distance,
    required this.onStopNavigation,
    required this.onShowExternalMaps,
    required this.onCenterOnRoute,
  });

  @override
  Widget build(BuildContext context) {
    final etaMinutes = int.tryParse(duration) ?? 0;
    final eta = DateTime.now().add(Duration(minutes: etaMinutes));
    final etaString = '${eta.hour}:${eta.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // ✕ Tugmasi
              GestureDetector(
                onTap: onStopNavigation,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.black54,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Vaqt va masofa
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          duration,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B8D5B),
                          ),
                        ),
                        const Text(
                          ' daq.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B8D5B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1B8D5B),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$distance km  •  $etaString',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Tashqi kartalar
              GestureDetector(
                onTap: onShowExternalMaps,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    color: Colors.black54,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Marshrut ko'rinishi
              GestureDetector(
                onTap: onCenterOnRoute,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.alt_route,
                    color: Colors.black54,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
