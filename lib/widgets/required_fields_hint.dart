import 'package:flutter/material.dart';

class RequiredFieldsHint extends StatelessWidget {
  const RequiredFieldsHint({super.key});

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    return Text(
      "* Required fields",
      style: textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
