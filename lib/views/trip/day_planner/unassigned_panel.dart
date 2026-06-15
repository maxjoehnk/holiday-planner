import 'package:flutter/material.dart';
import 'package:holiday_planner/l10n/app_localizations.dart';
import 'package:holiday_planner/src/rust/commands/trip_day.dart';
import 'package:holiday_planner/src/rust/models/trip_day.dart';
import 'package:uuid/uuid.dart';

import 'day_planner_types.dart';

class UnassignedPanel extends StatelessWidget {
  final UnassignedItems items;
  final void Function(SchedulableItemType type, UuidValue itemId) onAssign;
  final void Function(DraggedDayItem item) onItemDropped;

  const UnassignedPanel({
    super.key,
    required this.items,
    required this.onAssign,
    required this.onItemDropped,
  });

  @override
  Widget build(BuildContext context) {
    final total =
        items.pointsOfInterest.length + items.routes.length;
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return DragTarget<DraggedDayItem>(
      onWillAcceptWithDetails: (details) => details.data.sourceDayId != null,
      onAcceptWithDetails: (details) => onItemDropped(details.data),
      builder: (context, candidate, _) {
        final highlighted = candidate.isNotEmpty;
        if (total == 0 && !highlighted) {
          return const SizedBox.shrink();
        }
        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: highlighted ? colorScheme.primary : colorScheme.outlineVariant,
              width: highlighted ? 2 : 1,
            ),
          ),
          child: total == 0
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.inbox_outlined, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(loc.dayPlannerUnassignedSectionTitle(0),
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                )
              : Theme(
                  data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(8, 0, 8, 12),
                    leading: Icon(Icons.inbox_outlined,
                        color: colorScheme.primary),
                    title: Text(
                        loc.dayPlannerUnassignedSectionTitle(total),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                    children: [
                      ...items.pointsOfInterest.map((poi) => _Tile(
                            icon: Icons.place_outlined,
                            accent: colorScheme.primary,
                            title: poi.name,
                            subtitle:
                                poi.address.isEmpty ? null : poi.address,
                            onAssign: () => onAssign(
                                SchedulableItemType.pointOfInterest,
                                poi.id),
                          )),
                      ...items.routes.map((route) {
                        final km = (route.distanceMeters / 1000)
                            .toStringAsFixed(1);
                        final minutes =
                            (route.durationSeconds.toInt() / 60).round();
                        return _Tile(
                          icon: Icons.route_outlined,
                          accent: colorScheme.tertiary,
                          title: route.name,
                          subtitle:
                              '$km km · ~$minutes min${route.sport != null ? ' · ${route.sport}' : ''}',
                          onAssign: () => onAssign(
                              SchedulableItemType.route, route.id),
                        );
                      }),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final VoidCallback onAssign;

  const _Tile({
    required this.icon,
    required this.accent,
    required this.title,
    this.subtitle,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
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
      trailing: TextButton.icon(
        onPressed: onAssign,
        icon: const Icon(Icons.calendar_month_outlined, size: 18),
        label: Text(loc.dayPlannerAddToDay),
      ),
    );
  }
}
