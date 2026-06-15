import 'package:flutter/material.dart';
import 'package:holiday_planner/date_format.dart';
import 'package:holiday_planner/l10n/app_localizations.dart';
import 'package:holiday_planner/src/rust/commands/trip_day.dart';
import 'package:holiday_planner/src/rust/models/trip_day.dart';
import 'package:uuid/uuid.dart';

class AddToDaySelection {
  final SchedulableItemType type;
  final UuidValue itemId;
  final UuidValue? sourceDayId;

  const AddToDaySelection({
    required this.type,
    required this.itemId,
    this.sourceDayId,
  });
}

class AddToDaySheet extends StatelessWidget {
  final TripDayView targetDay;
  final UnassignedItems unassigned;
  final List<TripDayView> allDays;

  const AddToDaySheet({
    super.key,
    required this.targetDay,
    required this.unassigned,
    required this.allDays,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final label =
        targetDay.title ?? '${loc.dayPlannerDayLabel(targetDay.dayIndex)} · ${formatDate(targetDay.date)}';

    final fromOtherDays = <_DayItemSelection>[];
    for (final day in allDays) {
      if (day.id == targetDay.id) {
        continue;
      }
      for (final item in day.items) {
        item.details.map(
          pointOfInterest: (d) => fromOtherDays.add(_DayItemSelection(
            type: SchedulableItemType.pointOfInterest,
            itemId: d.id,
            sourceDayId: day.id,
            title: d.name,
            subtitle: day.title ?? loc.dayPlannerDayLabel(day.dayIndex),
            icon: Icons.place_outlined,
            accent: colorScheme.primary,
          )),
          route: (d) => fromOtherDays.add(_DayItemSelection(
            type: SchedulableItemType.route,
            itemId: d.id,
            sourceDayId: day.id,
            title: d.name,
            subtitle: day.title ?? loc.dayPlannerDayLabel(day.dayIndex),
            icon: Icons.route_outlined,
            accent: colorScheme.tertiary,
          )),
          accommodationCheckIn: (_) => null,
          accommodationCheckOut: (_) => null,
          accommodationStay: (_) => null,
          trainDeparture: (_) => null,
          trainArrival: (_) => null,
          reservation: (_) => null,
          carRentalPickUp: (_) => null,
          carRentalDropOff: (_) => null,
        );
      }
    }

    final empty =
        unassigned.pointsOfInterest.isEmpty &&
            unassigned.routes.isEmpty &&
            fromOtherDays.isEmpty;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  loc.dayPlannerAddSheetTitle(label),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: empty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              loc.dayPlannerAddSheetEmpty,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView(
                          controller: scrollController,
                          children: [
                            if (unassigned.pointsOfInterest.isNotEmpty ||
                                unassigned.routes.isNotEmpty)
                              _SectionHeader(loc.dayPlannerFromUnassigned),
                            ...unassigned.pointsOfInterest.map((poi) => _Row(
                                  icon: Icons.place_outlined,
                                  accent: colorScheme.primary,
                                  title: poi.name,
                                  subtitle:
                                      poi.address.isEmpty ? null : poi.address,
                                  onTap: () => Navigator.of(context).pop(
                                    AddToDaySelection(
                                      type: SchedulableItemType.pointOfInterest,
                                      itemId: poi.id,
                                    ),
                                  ),
                                )),
                            ...unassigned.routes.map((route) {
                              final km =
                                  (route.distanceMeters / 1000).toStringAsFixed(1);
                              final minutes =
                                  (route.durationSeconds.toInt() / 60).round();
                              return _Row(
                                icon: Icons.route_outlined,
                                accent: colorScheme.tertiary,
                                title: route.name,
                                subtitle: '$km km · ~$minutes min'
                                    '${route.sport != null ? ' · ${route.sport}' : ''}',
                                onTap: () => Navigator.of(context).pop(
                                  AddToDaySelection(
                                    type: SchedulableItemType.route,
                                    itemId: route.id,
                                  ),
                                ),
                              );
                            }),
                            if (fromOtherDays.isNotEmpty)
                              _SectionHeader(loc.dayPlannerFromOtherDays),
                            ...fromOtherDays.map((sel) => _Row(
                                  icon: sel.icon,
                                  accent: sel.accent,
                                  title: sel.title,
                                  subtitle: sel.subtitle,
                                  onTap: () => Navigator.of(context).pop(
                                    AddToDaySelection(
                                      type: sel.type,
                                      itemId: sel.itemId,
                                      sourceDayId: sel.sourceDayId,
                                    ),
                                  ),
                                )),
                          ],
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

class _DayItemSelection {
  final SchedulableItemType type;
  final UuidValue itemId;
  final UuidValue? sourceDayId;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const _DayItemSelection({
    required this.type,
    required this.itemId,
    required this.sourceDayId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });
}

class _SectionHeader extends StatelessWidget {
  final String text;

  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _Row({
    required this.icon,
    required this.accent,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: accent),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )),
      trailing: const Icon(Icons.add),
      onTap: onTap,
    );
  }
}
