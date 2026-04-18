import 'package:flutter/material.dart';

class MapControlButton extends StatelessWidget {
  final String heroTag;
  final Widget icon;
  final VoidCallback onTap;

  const MapControlButton({
    super.key,
    required this.heroTag,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: Material(
        elevation: 3,
        shape: const CircleBorder(),
        color: Colors.white,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}
