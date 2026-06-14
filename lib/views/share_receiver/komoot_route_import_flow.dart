import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/routes.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:holiday_planner/src/rust/commands/import_komoot_route.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/views/share_receiver/paste_komoot_url_dialog.dart';
import 'package:uuid/uuid.dart';

class KomootRouteImportFlow {
  static Future<void> startFromSharedUrl(BuildContext context, String url) async {
    final trips = await getTrips();
    if (!context.mounted) {
      return;
    }
    if (trips.isEmpty) {
      _showNoTripsDialog(context);
      return;
    }
    final trip = await showDialog<TripListModel?>(
      context: context,
      builder: (context) => _PickTripDialog(trips: trips),
    );
    if (trip == null || !context.mounted) {
      return;
    }
    await _import(context, trip.id, url);
  }

  static Future<void> startFromTripScreen(
    BuildContext context,
    UuidValue tripId,
  ) async {
    final url = await showDialog<String>(
      context: context,
      builder: (context) => const PasteKomootUrlDialog(),
    );
    if (url == null || !context.mounted) {
      return;
    }
    await _import(context, tripId, url);
  }

  static Future<void> _import(
    BuildContext context,
    UuidValue tripId,
    String url,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _FetchingDialog(),
    );
    try {
      await importKomootRoute(
        command: ImportKomootRoute(tripId: tripId, tourUrl: url),
      );
      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Route added'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Could not import route'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  static void _showNoTripsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Trips Available'),
        content: const Text(
            'You need to create a trip first before adding a route.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _FetchingDialog extends StatelessWidget {
  const _FetchingDialog();

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Expanded(child: Text('Fetching route…')),
        ],
      ),
    );
  }
}

class _PickTripDialog extends StatefulWidget {
  final List<TripListModel> trips;
  const _PickTripDialog({required this.trips});

  @override
  State<_PickTripDialog> createState() => _PickTripDialogState();
}

class _PickTripDialogState extends State<_PickTripDialog> {
  TripListModel? _selected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Komoot route'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select a trip to add this route to:'),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: widget.trips.map((trip) {
                    return RadioListTile<TripListModel>(
                      title: Text(trip.name),
                      subtitle: Text(
                        '${trip.startDate.toLocal().toString().split(' ')[0]} - ${trip.endDate.toLocal().toString().split(' ')[0]}',
                      ),
                      value: trip,
                      groupValue: _selected,
                      onChanged: (value) => setState(() => _selected = value),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.of(context).pop(_selected),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
