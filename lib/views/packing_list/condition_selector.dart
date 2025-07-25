import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';

import 'trip_duration_selector.dart';
import 'temperature_selector.dart';
import 'weather_selector.dart';

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
                    "Add Condition",
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              "Choose when this item should be included in your packing list:",
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _ConditionOption(
              icon: Icons.schedule,
              title: "Min Trip Duration",
              subtitle: "Include for trips longer than X days",
              color: colorScheme.tertiaryContainer,
              onColor: colorScheme.onTertiaryContainer,
              onTap: () => _onSelect(context,
                  const PackingListEntryCondition.minTripDuration(length: 1)),
            ),
            const SizedBox(height: 12),
            _ConditionOption(
              icon: Icons.schedule,
              title: "Max Trip Duration",
              subtitle: "Include for trips shorter than X days",
              color: colorScheme.tertiaryContainer,
              onColor: colorScheme.onTertiaryContainer,
              onTap: () => _onSelect(context,
                  const PackingListEntryCondition.maxTripDuration(length: 1)),
            ),
            const SizedBox(height: 12),
            _ConditionOption(
              icon: Icons.thermostat,
              title: "Min Temperature",
              subtitle: "Include when temperature is above X°C",
              color: colorScheme.errorContainer,
              onColor: colorScheme.onErrorContainer,
              onTap: () => _onSelect(context,
                  const PackingListEntryCondition.minTemperature(temperature: 20)),
            ),
            const SizedBox(height: 12),
            _ConditionOption(
              icon: Icons.ac_unit,
              title: "Max Temperature",
              subtitle: "Include when temperature is below X°C",
              color: colorScheme.primaryContainer,
              onColor: colorScheme.onPrimaryContainer,
              onTap: () => _onSelect(context,
                  const PackingListEntryCondition.maxTemperature(temperature: 0)),
            ),
            const SizedBox(height: 12),
            _ConditionOption(
              icon: Icons.cloud,
              title: "Weather Condition",
              subtitle: "Include based on weather forecast",
              color: colorScheme.secondaryContainer,
              onColor: colorScheme.onSecondaryContainer,
              onTap: () => _onSelect(
                  context,
                  const PackingListEntryCondition.weather(
                      condition: WeatherCondition.rain, minProbability: 0.5)),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
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
      tag: (_) => throw UnimplementedError(),
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
