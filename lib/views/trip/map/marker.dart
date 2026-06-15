import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class MapMarker extends Marker {
  MapMarker(
      {required super.point,
      required Color color,
      IconData icon = Icons.location_on,
      final Function()? onTap})
      : super(
            width: 40,
            height: 40,
            child: _MapMarker(color: color, icon: icon, onTap: onTap));
}

class _MapMarker extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Function()? onTap;

  const _MapMarker({required this.color, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    var colorScheme = ColorScheme.fromSeed(
        seedColor: color, brightness: Theme.of(context).brightness);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.onPrimary, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: colorScheme.onPrimary,
          size: 24,
        ),
      ),
    );
  }
}
