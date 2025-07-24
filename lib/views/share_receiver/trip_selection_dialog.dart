import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';

class TripSelectionDialog extends StatefulWidget {
  final List<TripListModel> trips;

  const TripSelectionDialog({
    super.key,
    required this.trips,
  });

  @override
  State<TripSelectionDialog> createState() => _TripSelectionDialogState();
}

class _TripSelectionDialogState extends State<TripSelectionDialog> {
  TripListModel? _selectedTrip;

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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedTrip == null ? null : _addTrainInformation,
          child: const Text('Add Trains'),
        ),
      ],
    );
  }

  Future<void> _addTrainInformation() async {
    if (_selectedTrip == null) {
      return;
    }
    Navigator.of(context).pop(_selectedTrip);
  }
}
