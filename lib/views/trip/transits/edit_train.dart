import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/transits.dart';
import 'package:holiday_planner/src/rust/commands/update_train.dart';
import 'package:holiday_planner/src/rust/models/transits.dart';

import 'train_form.dart';

class EditTrainPage extends StatefulWidget {
  final Train train;

  const EditTrainPage({super.key, required this.train});

  @override
  State<EditTrainPage> createState() => _EditTrainPageState();
}

class _EditTrainPageState extends State<EditTrainPage> {
  final GlobalKey<TrainFormState> _formKey = GlobalKey<TrainFormState>();
  bool _isLoading = false;
  String? _errorMessage;

  late final TrainFormData _initialData;

  @override
  void initState() {
    super.initState();
    _initialData = TrainFormData(
      trainNumber: widget.train.trainNumber ?? '',
      departureStationName: widget.train.departure.name,
      departureStationCity: widget.train.departure.city ?? '',
      departureStationCountry: widget.train.departure.country ?? '',
      departurePlatform: widget.train.departure.scheduledPlatform,
      arrivalStationName: widget.train.arrival.name,
      arrivalStationCity: widget.train.arrival.city ?? '',
      arrivalStationCountry: widget.train.arrival.country ?? '',
      arrivalPlatform: widget.train.arrival.scheduledPlatform,
      departureTime: widget.train.scheduledDepartureTime.toLocal(),
      arrivalTime: widget.train.scheduledArrivalTime.toLocal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Train"),
        centerTitle: true,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton(
              onPressed: _isLoading ? null : () => _formKey.currentState?.submit(),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Save"),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: TrainForm(
              key: _formKey,
              initialData: _initialData,
              onSubmit: _handleFormSubmit,
              isLoading: _isLoading,
              errorMessage: _errorMessage,
              onErrorDismiss: () => setState(() => _errorMessage = null),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _showDeleteConfirmation,
                icon: const Icon(Icons.delete_outline),
                label: const Text("Delete Train Booking"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _handleFormSubmit(TrainFormData formData) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final command = UpdateTrain(
        id: widget.train.id,
        trainNumber: formData.trainNumber.isEmpty ? null : formData.trainNumber,
        departureStationName: formData.departureStationName,
        departureStationCity: formData.departureStationCity,
        departureStationCountry: formData.departureStationCountry,
        departureScheduledPlatform: formData.departurePlatform,
        arrivalStationName: formData.arrivalStationName,
        arrivalStationCity: formData.arrivalStationCity,
        arrivalStationCountry: formData.arrivalStationCountry,
        arrivalScheduledPlatform: formData.arrivalPlatform,
        scheduledDepartureTime: formData.departureTime!,
        scheduledArrivalTime: formData.arrivalTime!,
      );

      await updateTrain(command: command);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Train booking updated successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to update train booking: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Train Booking'),
          content: const Text('Are you sure you want to delete this train booking? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTrain();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTrain() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await deleteTrain(trainId: widget.train.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Train booking deleted successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to delete train booking: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

}
