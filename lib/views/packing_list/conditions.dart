import 'package:flutter/material.dart';
import 'package:holiday_planner/colors.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/src/rust/api/tags.dart';
import 'package:uuid/uuid_value.dart';

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
      tag: (tag) => TagConditionChip(
          tagId: tag.tagId,
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

class TagConditionChip extends StatefulWidget {
  final UuidValue tagId;
  final Function()? onRemove;
  final Function()? onEdit;

  const TagConditionChip({
    super.key,
    required this.tagId,
    this.onRemove,
    this.onEdit,
  });

  @override
  State<TagConditionChip> createState() => _TagConditionChipState();
}

class _TagConditionChipState extends State<TagConditionChip> {
  String? tagName;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchTagName();
  }

  @override
  void didUpdateWidget(TagConditionChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the tag ID changed, refetch the tag name
    if (oldWidget.tagId != widget.tagId) {
      _fetchTagName();
    }
  }

  Future<void> _fetchTagName() async {
    try {
      final tag = await getTagById(id: widget.tagId);
      if (mounted) {
        setState(() {
          tagName = tag?.name;
          isLoading = false;
          hasError = tag == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String label;
    if (isLoading) {
      label = "Loading...";
    } else if (hasError || tagName == null) {
      label = "Unknown Tag";
    } else {
      label = tagName!;
    }

    return ConditionChip(
      tooltip: "Tag",
      label: label,
      iconData: Icons.label,
      color: CONDITION_TAG_COLOR,
      onEdit: widget.onEdit,
      onRemove: widget.onRemove,
    );
  }
}
