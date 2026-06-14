import 'package:flutter/material.dart';
import 'package:holiday_planner/date_format.dart';
import 'package:holiday_planner/services/data_change_bus.dart';
import 'package:holiday_planner/services/refreshable_data.dart';
import 'package:holiday_planner/src/rust/api/activity.dart';
import 'package:uuid/uuid.dart';

/// Append-only activity log for a single trip. Each entry is one
/// insert / update / soft-delete recorded server-side by triggers and
/// pulled to the local DB via the sync pipeline.
class TripActivityView extends StatefulWidget {
  final UuidValue tripId;
  final String tripName;

  const TripActivityView({
    required this.tripId,
    required this.tripName,
    super.key,
  });

  @override
  State<TripActivityView> createState() => _TripActivityViewState();
}

class _TripActivityViewState extends State<TripActivityView> {
  late final RefreshableData<List<TripActivityEntry>> _entries =
      RefreshableData<List<TripActivityEntry>>(
    fetch: () => listTripActivity(tripId: widget.tripId, limit: 100),
    refreshOn: [
      DataChangeBus.instance.onTripActivityChanged(widget.tripId),
    ],
  );

  @override
  void dispose() {
    _entries.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Activity · ${widget.tripName}')),
      body: SafeArea(
        child: StreamBuilder<List<TripActivityEntry>>(
          stream: _entries.stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final entries = snapshot.data!;
            if (entries.isEmpty) {
              return const Center(child: Text('No recent activity.'));
            }
            return ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => _ActivityTile(entry: entries[i]),
            );
          },
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final TripActivityEntry entry;
  const _ActivityTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final actor = entry.userDisplayName ?? entry.userEmail ?? 'Unknown';
    final action = _actionLabel(entry.action);
    final kindLabel = _kindLabel(entry.kind);
    final label = (entry.label?.isNotEmpty ?? false) ? entry.label! : kindLabel;
    return ListTile(
      leading: Icon(_actionIcon(entry.action), color: _actionColor(context, entry.action)),
      title: Text('$action: $label'),
      subtitle: Text('$kindLabel · $actor'),
      trailing: Text(
        _relative(entry.occurredAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

String _actionLabel(TripActivityAction action) => switch (action) {
      TripActivityAction.insert => 'Added',
      TripActivityAction.update => 'Edited',
      TripActivityAction.delete => 'Removed',
    };

IconData _actionIcon(TripActivityAction action) => switch (action) {
      TripActivityAction.insert => Icons.add_circle_outline,
      TripActivityAction.update => Icons.edit_outlined,
      TripActivityAction.delete => Icons.remove_circle_outline,
    };

Color _actionColor(BuildContext context, TripActivityAction action) {
  final cs = Theme.of(context).colorScheme;
  return switch (action) {
    TripActivityAction.insert => Colors.green,
    TripActivityAction.update => cs.primary,
    TripActivityAction.delete => cs.error,
  };
}

String _kindLabel(TripActivityKind kind) => switch (kind) {
      TripActivityKind.trip => 'Trip',
      TripActivityKind.accommodation => 'Accommodation',
      TripActivityKind.location => 'Location',
      TripActivityKind.reservation => 'Reservation',
      TripActivityKind.carRental => 'Car rental',
      TripActivityKind.pointOfInterest => 'Point of interest',
      TripActivityKind.train => 'Train',
      TripActivityKind.other => 'Item',
    };

String _relative(DateTime when) {
  final now = DateTime.now().toUtc();
  final delta = now.difference(when.toUtc());
  if (delta.inSeconds < 60) return 'just now';
  if (delta.inMinutes < 60) return '${delta.inMinutes}m ago';
  if (delta.inHours < 24) return '${delta.inHours}h ago';
  if (delta.inDays < 7) return '${delta.inDays}d ago';
  return formatDate(when.toLocal());
}
