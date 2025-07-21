import 'package:flutter/material.dart';
import 'package:holiday_planner/colors.dart';
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
  final Function()? onEdit;

  const ConditionTag({super.key, required this.condition, this.onRemove, this.onEdit});

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    
    return condition.map(
      minTripDuration: (duration) => ConditionChip(
          tooltip: "Min Trip Duration",
          label: "> ${duration.length} Day(s)",
          iconData: Icons.schedule,
          color: CONDITION_DURATION_COLOR,
          onEdit: onEdit,
          onRemove: onRemove),
      maxTripDuration: (duration) => ConditionChip(
          tooltip: "Max Trip Duration",
          label: "< ${duration.length} Day(s)",
          iconData: Icons.schedule,
          color: CONDITION_DURATION_COLOR,
          onEdit: onEdit,
          onRemove: onRemove),
      minTemperature: (temperature) => ConditionChip(
          tooltip: "Min Temperature",
          label: "> ${temperature.temperature}°C",
          iconData: Icons.thermostat,
          color: CONDITION_TEMPERATURE_COLOR,
          onEdit: onEdit,
          onRemove: onRemove),
      maxTemperature: (temperature) => ConditionChip(
          tooltip: "Max Temperature",
          label: "< ${temperature.temperature}°C",
          iconData: Icons.thermostat,
          color: CONDITION_TEMPERATURE_COLOR,
          onEdit: onEdit,
          onRemove: onRemove),
      weather: (weather) => ConditionChip(
          tooltip: "Weather",
          label: "${(weather.minProbability * 100).round()}%",
          iconData: _weatherIcons[weather.condition],
          color: CONDITION_WEATHER_COLOR,
          onEdit: onEdit,
          onRemove: onRemove),
      tag: (tag) => ConditionChip(
          tooltip: "Tag",
          label: tag.tag,
          iconData: Icons.label,
          color: CONDITION_TAG_COLOR,
          onEdit: onEdit,
          onRemove: onRemove,
      ),
    );
  }
}

class ConditionChip extends StatelessWidget {
  final String label;
  final Function()? onRemove;
  final Function()? onEdit;
  final IconData? iconData;
  final String? tooltip;
  final MaterialColor color;

  const ConditionChip(
      {super.key,
      required this.label,
      this.onEdit,
      this.onRemove,
      required this.color,
      this.iconData,
      this.tooltip});

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    
    if (onEdit == null) {
      return Chip(
        avatar: iconData != null ? Icon(
          iconData,
          size: 16,
          color: color.shade700,
        ) : null,
        backgroundColor: color.shade100,
        label: Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        onDeleted: onRemove,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }
    return InputChip(
      selected: true,
      showCheckmark: false,
      avatar: iconData != null ? Icon(
        iconData,
        size: 16,
        color: color.shade700,
      ) : null,
      onPressed: onEdit,
      backgroundColor: color.shade100,
      selectedColor: color.shade200,
      label: Text(
        label,
        style: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      onDeleted: onRemove,
      tooltip: tooltip,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
