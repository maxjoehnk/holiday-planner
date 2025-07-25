import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/transits.dart';
import 'package:holiday_planner/src/rust/commands/add_train.dart';
import 'package:uuid/uuid.dart';

import 'train_form.dart';

class AddTrainPage extends StatefulWidget {
  final UuidValue tripId;

  const AddTrainPage({super.key, required this.tripId});

  @override
  State<AddTrainPage> createState() => _AddTrainPageState();
}

class _AddTrainPageState extends State<AddTrainPage> {
  final GlobalKey<TrainFormState> _formKey = GlobalKey<TrainFormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Train"),
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
      body: TrainForm(
        key: _formKey,
        onSubmit: _handleFormSubmit,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        onErrorDismiss: () => setState(() => _errorMessage = null),
      ),
    );
  }

  void _handleFormSubmit(TrainFormData formData) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final command = AddTrain(
        tripId: widget.tripId,
        trainNumber: formData.trainNumber.isEmpty ? null : formData.trainNumber,
        departureStationName: formData.departureStationName,
        departureStationCity:
            formData.departureStationCity.isEmpty ? null : formData.departureStationCity,
        departureStationCountry:
            formData.departureStationCountry.isEmpty ? null : formData.departureStationCountry,
        departureScheduledPlatform: formData.departurePlatform,
        arrivalStationName: formData.arrivalStationName,
        arrivalStationCity:
            formData.arrivalStationCity.isEmpty ? null : formData.arrivalStationCity,
        arrivalStationCountry:
            formData.arrivalStationCountry.isEmpty ? null : formData.arrivalStationCountry,
        arrivalScheduledPlatform: formData.arrivalPlatform,
        scheduledDepartureTime: formData.departureTime!,
        scheduledArrivalTime: formData.arrivalTime!,
      );

      await addTrain(command: command);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Train booking added successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to add train booking: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
