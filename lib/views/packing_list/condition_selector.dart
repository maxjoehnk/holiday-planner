import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:uuid/uuid_value.dart';
import 'package:holiday_planner/l10n/app_localizations.dart';

import 'trip_duration_selector.dart';
import 'temperature_selector.dart';
import 'weather_selector.dart';
import 'tag_selector.dart';
import 'pollen_selector.dart';

class ConditionSelector extends StatelessWidget {
  final Function(PackingListEntryCondition) onSelect;

  const ConditionSelector({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    
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
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.tune,
                    size: 20,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.addConditionTitle,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.conditionSelectorIntro,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _ConditionOption(
              icon: Icons.schedule,
              title: AppLocalizations.of(context)!.conditionMinTripDurationTitle,
              subtitle: AppLocalizations.of(context)!.conditionMinTripDurationSubtitle,
              color: colorScheme.tertiaryContainer,
              onColor: colorScheme.onTertiaryContainer,
              onTap: () => _onSelect(context,
                  const PackingListEntryCondition.minTripDuration(length: 1)),
            ),
            const SizedBox(height: 12),
            _ConditionOption(
              icon: Icons.schedule,
              title: AppLocalizations.of(context)!.conditionMaxTripDurationTitle,
              subtitle: AppLocalizations.of(context)!.conditionMaxTripDurationSubtitle,
              color: colorScheme.tertiaryContainer,
              onColor: colorScheme.onTertiaryContainer,
              onTap: () => _onSelect(context,
                  const PackingListEntryCondition.maxTripDuration(length: 1)),
            ),
            const SizedBox(height: 12),
            _ConditionOption(
              icon: Icons.thermostat,
              title: AppLocalizations.of(context)!.conditionMinTemperatureTitle,
              subtitle: AppLocalizations.of(context)!.conditionMinTemperatureSubtitle,
              color: colorScheme.errorContainer,
              onColor: colorScheme.onErrorContainer,
              onTap: () => _onSelect(context,
                  const PackingListEntryCondition.minTemperature(temperature: 20)),
            ),
            const SizedBox(height: 12),
            _ConditionOption(
              icon: Icons.ac_unit,
              title: AppLocalizations.of(context)!.conditionMaxTemperatureTitle,
              subtitle: AppLocalizations.of(context)!.conditionMaxTemperatureSubtitle,
              color: colorScheme.primaryContainer,
              onColor: colorScheme.onPrimaryContainer,
              onTap: () => _onSelect(context,
                  const PackingListEntryCondition.maxTemperature(temperature: 0)),
            ),
            const SizedBox(height: 12),
            _ConditionOption(
              icon: Icons.cloud,
              title: AppLocalizations.of(context)!.conditionWeatherTitle,
              subtitle: AppLocalizations.of(context)!.conditionWeatherSubtitle,
              color: colorScheme.secondaryContainer,
              onColor: colorScheme.onSecondaryContainer,
              onTap: () => _onSelect(
                  context,
                  const PackingListEntryCondition.weather(
                      condition: WeatherCondition.rain, minProbability: 0.5)),
            ),
            const SizedBox(height: 12),
            _ConditionOption(
              icon: Icons.label,
              title: AppLocalizations.of(context)!.conditionTripTagTitle,
              subtitle: AppLocalizations.of(context)!.conditionTripTagSubtitle,
              color: colorScheme.surfaceContainerHighest,
              onColor: colorScheme.onSurface,
              onTap: () => _onSelect(
                  context,
                  PackingListEntryCondition.tag(tagId: UuidValue.fromString("00000000-0000-0000-0000-000000000000"))),
            ),
            const SizedBox(height: 12),
            _ConditionOption(
              icon: Icons.local_florist,
              title: AppLocalizations.of(context)!.conditionPollenTitle,
              subtitle: AppLocalizations.of(context)!.conditionPollenSubtitle,
              color: colorScheme.tertiaryContainer,
              onColor: colorScheme.onTertiaryContainer,
              onTap: () => _onSelect(
                  context,
                  const PackingListEntryCondition.pollen(
                      pollenType: PollenType.grass, minIndex: 3)),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _onSelect(BuildContext context, PackingListEntryCondition condition) async {
    var nextDialog = condition.map(
      minTripDuration: (_) => TripDurationSelector(onSelect: onSelect, threshold: TripDuration.min),
      maxTripDuration: (_) => TripDurationSelector(onSelect: onSelect, threshold: TripDuration.max),
      minTemperature: (_) => TemperatureSelector(onSelect: onSelect, threshold: Temperature.min),
      maxTemperature: (_) => TemperatureSelector(onSelect: onSelect, threshold: Temperature.max),
      weather: (weather) => WeatherSelector(onSelect: onSelect, condition: weather.condition, minProbability: weather.minProbability),
      tag: (_) => TagSelector(onSelect: onSelect),
      pollen: (pollen) => PollenSelector(onSelect: onSelect, pollenType: pollen.pollenType, minIndex: pollen.minIndex),
    );
    Navigator.pop(context);
    showDialog(context: context, builder: (context) => nextDialog);
  }
}

class _ConditionOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color onColor;
  final VoidCallback onTap;

  const _ConditionOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: onColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: onColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: onColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: onColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
