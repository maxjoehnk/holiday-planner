import 'package:holiday_planner/src/rust/commands/trip_day.dart';
import 'package:uuid/uuid.dart';

class DraggedDayItem {
  final SchedulableItemType type;
  final UuidValue itemId;
  final UuidValue? sourceDayId;

  const DraggedDayItem({
    required this.type,
    required this.itemId,
    this.sourceDayId,
  });
}
