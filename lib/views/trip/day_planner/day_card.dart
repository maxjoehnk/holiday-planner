import 'package:flutter/material.dart';
import 'package:holiday_planner/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:holiday_planner/src/rust/commands/trip_day.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/src/rust/models/trip_day.dart';
import 'package:uuid/uuid.dart';

import 'day_item_row.dart';
import 'day_planner_types.dart';
import 'day_title_field.dart';

class DayCard extends StatelessWidget {
  final TripDayView day;
  final ValueChanged<String?> onTitleChanged;
  final VoidCallback onAddPressed;
  final VoidCallback onEditLocations;
  final void Function(SchedulableItemType type, UuidValue itemId) onUnassign;
  final void Function(SchedulableItemType type, UuidValue itemId) onMove;
  final void Function(DayItemDetails details) onItemTap;
  final void Function(DraggedDayItem item) onItemDropped;

  const DayCard({
    super.key,
    required this.day,
    required this.onTitleChanged,
    required this.onAddPressed,
    required this.onEditLocations,
    required this.onUnassign,
    required this.onMove,
    required this.onItemTap,
    required this.onItemDropped,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    return DragTarget<DraggedDayItem>(
      onWillAcceptWithDetails: (details) =>
          details.data.sourceDayId != day.id,
      onAcceptWithDetails: (details) => onItemDropped(details.data),
      builder: (context, candidate, _) {
        final highlighted = candidate.isNotEmpty;
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: highlighted
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: highlighted ? 2 : 1,
            ),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  day: day,
                  onTitleChanged: onTitleChanged,
                  onEditLocations: onEditLocations,
                ),
                if (day.items.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Column(
                    children: day.items
                        .map((item) => DayItemRow(
                              item: item,
                              dayId: day.id,
                              onUnassign: onUnassign,
                              onMove: onMove,
                              onTap: () => onItemTap(item.details),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onAddPressed,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(loc.dayPlannerAddToDay),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final TripDayView day;
  final ValueChanged<String?> onTitleChanged;
  final VoidCallback onEditLocations;

  const _Header({
    required this.day,
    required this.onTitleChanged,
    required this.onEditLocations,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final localDate = day.date.toLocal();
    final dateLine =
        '${loc.dayPlannerDayLabel(day.dayIndex)} · ${DateFormat('EEE, MMM d').format(localDate)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: DayTitleField(
                initialTitle: day.title,
                placeholder: loc.dayPlannerTitleHint,
                onSubmitted: onTitleChanged,
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (day.weather != null) ...[
              const SizedBox(width: 8),
              _WeatherStrip(weather: day.weather!),
            ],
          ],
        ),
        Row(
          children: [
            Text(
              dateLine,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              ' · ',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Expanded(
              child: _LocationSummary(
                day: day,
                onTap: onEditLocations,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LocationSummary extends StatelessWidget {
  final TripDayView day;
  final VoidCallback onTap;

  const _LocationSummary({required this.day, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (day.locations.isEmpty) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_location_alt_outlined,
                  size: 14, color: colorScheme.primary),
              const SizedBox(width: 2),
              Text(
                loc.dayPlannerAddLocation,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final primary = day.locations.firstWhere(
      (l) => l.isPrimary,
      orElse: () => day.locations.first,
    );
    final extra = day.locations.length - 1;
    final label =
        '${primary.city}${primary.country.isEmpty ? '' : ', ${primary.country}'}${extra > 0 ? '  +$extra' : ''}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on,
                size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherStrip extends StatelessWidget {
  final DayWeather weather;

  const _WeatherStrip({required this.weather});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = _iconFor(weather.condition);
    final rainPct = (weather.precipitationProbability * 100).round();
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          '${weather.maxTemperature.round()}° / ${weather.minTemperature.round()}°',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (rainPct > 10) ...[
          const SizedBox(width: 10),
          Icon(Icons.umbrella, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            '$rainPct%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }

  IconData _iconFor(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return Icons.wb_sunny;
      case WeatherCondition.rain:
        return Icons.grain;
      case WeatherCondition.clouds:
        return Icons.cloud_outlined;
      case WeatherCondition.snow:
        return Icons.ac_unit;
      case WeatherCondition.thunderstorm:
        return Icons.thunderstorm;
    }
  }
}

