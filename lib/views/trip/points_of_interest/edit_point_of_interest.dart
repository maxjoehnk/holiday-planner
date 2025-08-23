import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/points_of_interest.dart';
import 'package:holiday_planner/src/rust/commands/update_trip_point_of_interest.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/views/trip/points_of_interest/point_of_interest_form.dart';

class EditPointOfInterest extends StatefulWidget {
  final PointOfInterestModel pointOfInterest;

  const EditPointOfInterest({super.key, required this.pointOfInterest});

  @override
  State<EditPointOfInterest> createState() => _EditPointOfInterestState();
}

class _EditPointOfInterestState extends State<EditPointOfInterest> {
  final GlobalKey<PointOfInterestFormState> _formKey = GlobalKey<PointOfInterestFormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Point of Interest"),
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
            child: PointOfInterestForm(
              tripId: widget.pointOfInterest.tripId,
              key: _formKey,
              initialData: PointOfInterestFormData(
                id: widget.pointOfInterest.id,
                name: widget.pointOfInterest.name,
                address: widget.pointOfInterest.address,
                website: widget.pointOfInterest.website,
                openingHours: widget.pointOfInterest.openingHours,
                price: widget.pointOfInterest.price,
                phoneNumber: widget.pointOfInterest.phoneNumber,
                note: widget.pointOfInterest.note,
              ),
              onSubmit: _handleFormSubmit,
              isLoading: _isLoading,
              errorMessage: _errorMessage,
              onErrorDismiss: () => setState(() => _errorMessage = null),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : () => _deletePointOfInterest(context),
                icon: const Icon(Icons.delete_outline),
                label: const Text("Delete Point of Interest"),
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

  Future<void> _handleFormSubmit(PointOfInterestFormData formData) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final command = UpdateTripPointOfInterest(
        id: widget.pointOfInterest.id,
        name: formData.name,
        address: formData.address,
        website: formData.website,
        openingHours: formData.openingHours,
        price: formData.price,
        phoneNumber: formData.phoneNumber,
        note: formData.note,
        coordinate: formData.coordinate,
      );

      await updateTripPointOfInterest(command: command);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to update point of interest: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deletePointOfInterest(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Point of Interest'),
        content: Text('Are you sure you want to delete "${widget.pointOfInterest.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await deletePointOfInterest(pointOfInterestId: widget.pointOfInterest.id);
        if (mounted) {
          Navigator.of(context).pop(); // Go back to the list
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error deleting point of interest: $e';
          _isLoading = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting point of interest: $e')),
          );
        }
      }
    }
  }
}
