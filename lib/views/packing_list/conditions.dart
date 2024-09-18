import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';

Map<WeatherCondition, IconData> _weatherIcons = {
  WeatherCondition.sunny: Icons.wb_sunny,
  WeatherCondition.rain: Icons.water_drop,
  WeatherCondition.clouds: Icons.cloud,
  WeatherCondition.snow: Icons.snowing,
  WeatherCondition.thunderstorm: Icons.thunderstorm,
};

class ConditionTag extends StatelessWidget {
  final PackingListEntryCondition condition;
  final Function()? onRemove;

  const ConditionTag({super.key, required this.condition, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return condition.map(
      minTripDuration: (duration) => ConditionChip(
          tooltip: "Min Trip Duration",
          label: "> ${duration.length} Day(s)",
          color: Colors.orange.shade100,
          onRemove: onRemove),
      maxTripDuration: (duration) => ConditionChip(
          tooltip: "Max Trip Duration",
          label: "< ${duration.length} Day(s)",
          color: Colors.orange.shade100,
          onRemove: onRemove),
      minTemperature: (temperature) => ConditionChip(
          tooltip: "Min Temperature",
          label: "> ${temperature.temperature}°C",
          color: Colors.blue.shade100,
          onRemove: onRemove),
      maxTemperature: (temperature) => ConditionChip(
          tooltip: "Max Temperature",
          label: "< ${temperature.temperature}°C",
          color: Colors.blue.shade100,
          onRemove: onRemove),
      weather: (weather) => ConditionChip(
          tooltip: "Weather",
          label: "${(weather.minProbability * 100).round()}%",
          iconData: _weatherIcons[weather.condition],
          color: Colors.green.shade100,
          onRemove: onRemove),
      tag: (tag) => ConditionChip(
          tooltip: "Tag",
          label: tag.tag,
          iconData: Icons.label,
          color: Colors.yellow.shade100,
          onRemove: onRemove),
    );
  }
}

class ConditionChip extends StatelessWidget {
  final String label;
  final Function()? onRemove;
  final IconData? iconData;
  final String? tooltip;
  final Color color;

  const ConditionChip(
      {super.key,
      required this.label,
      this.onRemove,
      required this.color,
      this.iconData,
      this.tooltip});

  @override
  Widget build(BuildContext context) {
    return InputChip(
      selected: true,
      showCheckmark: false,
      avatar: iconData != null ? Icon(iconData) : null,
      onPressed: () {},
      color: WidgetStateProperty.all(color),
      label: Text(label),
      onDeleted: onRemove,
      tooltip: tooltip,
    );
  }
}
