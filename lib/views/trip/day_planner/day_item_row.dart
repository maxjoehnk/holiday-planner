import 'package:flutter/material.dart';
import 'package:holiday_planner/date_format.dart';
import 'package:holiday_planner/l10n/app_localizations.dart';
import 'package:holiday_planner/src/rust/commands/trip_day.dart';
import 'package:holiday_planner/src/rust/models/bookings.dart';
import 'package:holiday_planner/src/rust/models/trip_day.dart';
import 'package:uuid/uuid.dart';

import 'day_planner_types.dart';

enum DayItemAction { unassign, move }

class DayItemRow extends StatelessWidget {
  final DayItem item;
  final UuidValue? dayId;
  final void Function(SchedulableItemType type, UuidValue itemId)? onUnassign;
  final void Function(SchedulableItemType type, UuidValue itemId)? onMove;
  final VoidCallback? onTap;

  const DayItemRow({
    super.key,
    required this.item,
    required this.dayId,
    this.onUnassign,
    this.onMove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Widget tile;
    if (_isOvernightStay) {
      tile = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Icon(_icon, size: 16, color: _accentColor(colorScheme)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      tile = ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        leading: _Glyph(icon: _icon, color: _accentColor(colorScheme)),
        title: Text(_title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: _subtitle == null
            ? null
            : Text(_subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onSurfaceVariant)),
        trailing: _trailing(context),
        onTap: onTap,
      );
    }

    final actionable = _actionablePayload();
    if (actionable == null || dayId == null) {
      return tile;
    }

    final dismissible = Dismissible(
      key: ValueKey('day-item-${actionable.itemId}'),
      direction: DismissDirection.endToStart,
      background: _SwipeBackground(),
      confirmDismiss: (_) async {
        onUnassign?.call(actionable.type, actionable.itemId);
        return true;
      },
      child: tile,
    );

    final draggable = DraggedDayItem(
      type: actionable.type,
      itemId: actionable.itemId,
      sourceDayId: dayId,
    );
    return LongPressDraggable<DraggedDayItem>(
      data: draggable,
      delay: const Duration(milliseconds: 250),
      feedback: _DragFeedback(
        title: _title,
        color: _accentColor(colorScheme),
        icon: _icon,
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: dismissible),
      child: dismissible,
    );
  }

  bool get _isOvernightStay => item.details.map(
        pointOfInterest: (_) => false,
        route: (_) => false,
        accommodationCheckIn: (_) => false,
        accommodationCheckOut: (_) => false,
        accommodationStay: (_) => true,
        trainDeparture: (_) => false,
        trainArrival: (_) => false,
        reservation: (_) => false,
        carRentalPickUp: (_) => false,
        carRentalDropOff: (_) => false,
      );

  Widget? _trailing(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final time = item.scheduledAt;
    final actionable = _actionablePayload();

    if (actionable == null) {
      return time == null
          ? null
          : Text(
              formatTime(time),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (time != null)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              formatTime(time),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        PopupMenuButton<DayItemAction>(
          tooltip: '',
          icon: const Icon(Icons.more_vert, size: 20),
          onSelected: (action) {
            switch (action) {
              case DayItemAction.unassign:
                onUnassign?.call(actionable.type, actionable.itemId);
                break;
              case DayItemAction.move:
                onMove?.call(actionable.type, actionable.itemId);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: DayItemAction.move,
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, size: 18),
                  const SizedBox(width: 8),
                  Text(loc.dayPlannerMoveToDay),
                ],
              ),
            ),
            PopupMenuItem(
              value: DayItemAction.unassign,
              child: Row(
                children: [
                  const Icon(Icons.remove_circle_outline, size: 18),
                  const SizedBox(width: 8),
                  Text(loc.dayPlannerRemoveFromDay),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  _ActionablePayload? _actionablePayload() {
    return item.details.map(
      pointOfInterest: (d) => _ActionablePayload(
          type: SchedulableItemType.pointOfInterest, itemId: d.id),
      route: (d) =>
          _ActionablePayload(type: SchedulableItemType.route, itemId: d.id),
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

  Color _accentColor(ColorScheme colorScheme) {
    return item.details.map(
      pointOfInterest: (_) => colorScheme.primary,
      route: (_) => colorScheme.tertiary,
      accommodationCheckIn: (_) => Colors.brown.shade400,
      accommodationCheckOut: (_) => Colors.brown.shade400,
      accommodationStay: (_) => Colors.brown.shade300,
      trainDeparture: (_) => Colors.indigo,
      trainArrival: (_) => Colors.indigo,
      reservation: (_) => Colors.orange.shade700,
      carRentalPickUp: (_) => Colors.green.shade700,
      carRentalDropOff: (_) => Colors.green.shade700,
    );
  }

  IconData get _icon {
    return item.details.map(
      pointOfInterest: (_) => Icons.place_outlined,
      route: (_) => Icons.route_outlined,
      accommodationCheckIn: (_) => Icons.login,
      accommodationCheckOut: (_) => Icons.logout,
      accommodationStay: (_) => Icons.hotel_outlined,
      trainDeparture: (_) => Icons.train,
      trainArrival: (_) => Icons.train,
      reservation: (item) => item.category == ReservationCategory.restaurant
          ? Icons.restaurant
          : Icons.local_activity,
      carRentalPickUp: (_) => Icons.car_rental,
      carRentalDropOff: (_) => Icons.car_rental,
    );
  }

  String get _title {
    return item.details.map(
      pointOfInterest: (d) => d.name,
      route: (d) => d.name,
      accommodationCheckIn: (d) => 'Check-in · ${d.name}',
      accommodationCheckOut: (d) => 'Check-out · ${d.name}',
      accommodationStay: (d) => d.name,
      trainDeparture: (d) =>
          'Train · ${d.trainNumber ?? 'Departure'} from ${d.station}',
      trainArrival: (d) =>
          'Train · ${d.trainNumber ?? 'Arrival'} at ${d.station}',
      reservation: (d) => d.title,
      carRentalPickUp: (d) => 'Car pick-up · ${d.provider}',
      carRentalDropOff: (d) => 'Car drop-off · ${d.provider}',
    );
  }

  String? get _subtitle {
    return item.details.map(
      pointOfInterest: (d) => d.address.isEmpty ? null : d.address,
      route: (d) {
        final km = (d.distanceMeters / 1000).toStringAsFixed(1);
        final minutes = (d.durationSeconds.toInt() / 60).round();
        return '$km km · ~$minutes min${d.sport != null ? ' · ${d.sport}' : ''}';
      },
      accommodationCheckIn: (d) => d.address,
      accommodationCheckOut: (d) => d.address,
      accommodationStay: (_) => 'Staying overnight',
      trainDeparture: (d) => d.seat == null ? null : 'Seat ${d.seat}',
      trainArrival: (_) => null,
      reservation: (d) => d.address,
      carRentalPickUp: (d) => d.address,
      carRentalDropOff: (d) => d.address,
    );
  }
}

class _ActionablePayload {
  final SchedulableItemType type;
  final UuidValue itemId;
  const _ActionablePayload({required this.type, required this.itemId});
}

class _SwipeBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.remove_circle_outline,
          color: colorScheme.onErrorContainer),
    );
  }
}

class _DragFeedback extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;

  const _DragFeedback({
    required this.title,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glyph extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _Glyph({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
