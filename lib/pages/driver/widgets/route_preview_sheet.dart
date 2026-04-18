import 'package:flutter/material.dart';

class RoutePreviewSheet extends StatelessWidget {
  final String duration;
  final String distance;
  final VoidCallback onStartNavigation;

  const RoutePreviewSheet({
    super.key,
    required this.duration,
    required this.distance,
    required this.onStartNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tutqich
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              if (distance.isNotEmpty && duration.isNotEmpty) ...[
                // Sarlavha + masofa bir qatorda
                Row(
                  children: [
                    const Text(
                      'Tez Yordam',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$duration daq.',
                      style: const TextStyle(
                        color: Color(0xFF81C784),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' ($distance km)',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Eng tezkor marshrut',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 14),
                // Tugmalar
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onStartNavigation,
                    icon: const Icon(
                      Icons.navigation,
                      color: Colors.black87,
                      size: 22,
                    ),
                    label: const Text(
                      'Boshlash',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF80DEEA),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
