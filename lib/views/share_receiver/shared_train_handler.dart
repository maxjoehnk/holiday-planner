import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/transits.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:holiday_planner/src/rust/commands/parse_shared_train_data.dart';
import 'package:holiday_planner/src/rust/commands/parse_train_data.dart';
import 'package:holiday_planner/src/rust/models.dart';

import 'train_confirmation_dialog.dart';
import 'trip_selection_dialog.dart';

class SharedTrainHandler {
  static Future<void> handleSharedText(
      BuildContext context, String sharedText) async {
    try {
      final parsedJourney = await parseTrainData(
        command: ParseTrainData(
          sharedText: sharedText,
        ),
      );

      if (!context.mounted) {
        return;
      }

      if (parsedJourney.segments.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data found')),
        );
        return;
      }

      bool? result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return TrainConfirmationDialog(
            parsedJourney: parsedJourney,
          );
        },
      );

      if (result != true) {
        return;
      }

      final trips = await getTrips();

      if (!context.mounted) {
        return;
      }

      if (trips.isEmpty) {
        _showNoTripsDialog(context);
        return;
      }

      var selectedTrip = await showDialog<TripListModel?>(
        context: context,
        builder: (BuildContext context) {
          return TripSelectionDialog(
            trips: trips,
          );
        },
      );

      if (selectedTrip == null) {
        return;
      }

      await importParsedTrainJourney(
          command: ImportParsedTrainJourney(
              tripId: selectedTrip.id, journey: parsedJourney));

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Train information added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      _showErrorDialog(context, 'Failed to parse train information: $e');
    }
  }

  static void _showNoTripsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Trips Available'),
          content: const Text(
              'You need to create a trip first before adding train information.'),
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
