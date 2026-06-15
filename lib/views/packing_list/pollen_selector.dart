import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/l10n/app_localizations.dart';

const Map<PollenType, IconData> _pollenIcons = {
  PollenType.grass: Icons.grass,
  PollenType.tree: Icons.park,
  PollenType.weed: Icons.local_florist,
};

String labelForPollenType(PollenType type, BuildContext context) {
  switch (type) {
    case PollenType.grass:
      return AppLocalizations.of(context)!.pollenTypeGrass;
    case PollenType.tree:
      return AppLocalizations.of(context)!.pollenTypeTree;
    case PollenType.weed:
      return AppLocalizations.of(context)!.pollenTypeWeed;
  }
}

IconData iconForPollenType(PollenType type) => _pollenIcons[type] ?? Icons.local_florist;

class PollenSelector extends StatefulWidget {
  final PollenType? pollenType;
  final int? minIndex;
  final Function(PackingListEntryCondition) onSelect;

  const PollenSelector({
    super.key,
    required this.onSelect,
    this.pollenType,
    this.minIndex,
  });

  @override
  State<PollenSelector> createState() => _PollenSelectorState();
}

class _PollenSelectorState extends State<PollenSelector> {
  PollenType _selectedType = PollenType.grass;
  double _index = 3;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.pollenType ?? PollenType.grass;
    _index = (widget.minIndex ?? 3).clamp(0, 5).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    iconForPollenType(_selectedType),
                    size: 20,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.pollenSelectorTitle,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.pollenSelectorDescription,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.pollenTypeLabel,
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PollenType.values.map((type) {
                final isSelected = type == _selectedType;
                return FilterChip(
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = type;
                      });
                    }
                  },
                  avatar: Icon(
                    iconForPollenType(type),
                    size: 16,
                    color: isSelected
                        ? colorScheme.onTertiaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                  label: Text(labelForPollenType(type, context)),
                  backgroundColor: colorScheme.surface,
                  selectedColor: colorScheme.tertiaryContainer,
                  checkmarkColor: colorScheme.onTertiaryContainer,
                  side: BorderSide(
                    color: isSelected
                        ? colorScheme.tertiaryContainer
                        : colorScheme.outline,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.pollenIndexLabel(_index.round()),
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _index,
              min: 0,
              max: 5,
              divisions: 5,
              label: _index.round().toString(),
              onChanged: (value) => setState(() => _index = value),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _onConfirm,
                  child: Text(widget.pollenType != null
                      ? AppLocalizations.of(context)!.save
                      : AppLocalizations.of(context)!.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onConfirm() {
    Navigator.pop(context);
    final condition = PackingListEntryCondition.pollen(
      pollenType: _selectedType,
      minIndex: _index.round(),
    );
    widget.onSelect(condition);
  }
}
