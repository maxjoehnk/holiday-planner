import 'package:flutter/material.dart';
import 'package:holiday_planner/l10n/app_localizations.dart';

class SheetTopBar extends StatelessWidget {
  final VoidCallback? onEdit;
  final Widget? leading;

  const SheetTopBar({super.key, this.onEdit, this.leading});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryFixedDim,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          if (leading != null)
            Align(
              alignment: Alignment.centerLeft,
              child: leading,
            ),
          if (onEdit != null)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: AppLocalizations.of(context)!.editLabel,
                onPressed: onEdit,
              ),
            ),
        ],
      ),
    );
  }
}
