import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/points_of_interest.dart';
import 'package:holiday_planner/src/rust/commands/add_trip_point_of_interest.dart';
import 'package:holiday_planner/views/trip/points_of_interest/point_of_interest_form.dart';
import 'package:uuid/uuid.dart';

class AddPointOfInterest extends StatefulWidget {
  final UuidValue tripId;

  const AddPointOfInterest({super.key, required this.tripId});

  @override
  State<AddPointOfInterest> createState() => _AddPointOfInterestState();
}

class _AddPointOfInterestState extends State<AddPointOfInterest> {
  final GlobalKey<PointOfInterestFormState> _formKey = GlobalKey<PointOfInterestFormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Point of Interest"),
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
      body: PointOfInterestForm(
        key: _formKey,
        initialData: PointOfInterestFormData(
          name: '',
          address: '',
          tripId: widget.tripId,
        ),
        onSubmit: _handleFormSubmit,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        onErrorDismiss: () => setState(() => _errorMessage = null),
      ),
    );
  }

  Future<void> _handleFormSubmit(PointOfInterestFormData formData) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await addTripPointOfInterest(
        command: AddTripPointOfInterest(
          name: formData.name,
          address: formData.address,
          website: formData.website,
          openingHours: formData.openingHours,
          price: formData.price,
          phoneNumber: formData.phoneNumber,
          note: formData.note,
          tripId: widget.tripId,
        ),
      );
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to add point of interest: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }
}
