import 'package:flutter/material.dart';

class SectionTheme extends StatelessWidget {
  final MaterialColor color;
  final Widget child;

  const SectionTheme({super.key, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var luminance = color.computeLuminance();
    var foregroundColor = luminance > 0.5 ? Colors.black : Colors.white;
    return Theme(
        data: ThemeData.from(
          colorScheme: colorScheme.copyWith(
            primary: color,
            primaryContainer: color.shade100,
            onPrimary: foregroundColor,
          ),
        ),
        child: child);
  }
}
