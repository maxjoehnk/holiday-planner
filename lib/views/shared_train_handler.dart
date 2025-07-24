import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:holiday_planner/src/rust/api/transits.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/src/rust/commands/parse_shared_train_data.dart';
import 'package:uuid/uuid.dart';

class SharedTrainHandler {
  static Future<void> handleSharedText(BuildContext context, String sharedText) async {
    // Check if the shared text looks like train information
    if (_isTrainInformation(sharedText)) {
      await _showTripSelectionDialog(context, sharedText);
    }
  }

  static bool _isTrainInformation(String text) {
    // Simple heuristic to detect DB train information
    return text.contains('→') &&
        (text.contains('IC ') ||
            text.contains('ICE ') ||
            text.contains('RE ') ||
            text.contains('RB ')) &&
        text.contains('Platform');
  }

  static Future<void> _showTripSelectionDialog(BuildContext context, String sharedText) async {
    try {
      // Get all trips
      final trips = await getTrips();

      if (!context.mounted) return;

      if (trips.isEmpty) {
        _showNoTripsDialog(context);
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return TripSelectionDialog(
            trips: trips,
            sharedText: sharedText,
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      _showErrorDialog(context, 'Failed to load trips: $e');
    }
  }

  static void _showNoTripsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Trips Available'),
          content: const Text('You need to create a trip first before adding train information.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class TripSelectionDialog extends StatefulWidget {
  final List<TripListModel> trips;
  final String sharedText;

  const TripSelectionDialog({
    super.key,
    required this.trips,
    required this.sharedText,
  });

  @override
  State<TripSelectionDialog> createState() => _TripSelectionDialogState();
}

class _TripSelectionDialogState extends State<TripSelectionDialog> {
  TripListModel? _selectedTrip;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Train Information'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select a trip to add the train information to:'),
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
                      groupValue: _selectedTrip,
                      onChanged: (TripListModel? value) {
                        setState(() {
                          _selectedTrip = value;
                        });
                      },
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
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading || _selectedTrip == null ? null : _addTrainInformation,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Trains'),
        ),
      ],
    );
  }

  Future<void> _addTrainInformation() async {
    if (_selectedTrip == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse and add the shared train data
      await parseSharedTrainData(
        command: ParseSharedTrainData(
          tripId: _selectedTrip!.id,
          sharedText: widget.sharedText,
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Train information added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add train information: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
