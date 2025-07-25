import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/bookings.dart';
import 'package:holiday_planner/src/rust/commands/update_car_rental.dart';
import 'package:holiday_planner/src/rust/models/bookings.dart';
import 'package:holiday_planner/views/trip/bookings/car_rental_form.dart';

class EditCarRentalPage extends StatefulWidget {
  final CarRental carRental;

  const EditCarRentalPage({super.key, required this.carRental});

  @override
  State<EditCarRentalPage> createState() => _EditCarRentalPageState();
}

class _EditCarRentalPageState extends State<EditCarRentalPage> {
  final _formKey = GlobalKey<CarRentalFormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Car Rental"),
        centerTitle: true,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
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
            child: CarRentalForm(
              key: _formKey,
              initialData: CarRentalFormData(
                id: widget.carRental.id,
                provider: widget.carRental.provider,
                pickUpLocation: widget.carRental.pickUpLocation,
                pickUpDate: widget.carRental.pickUpDate.toLocal(),
                returnDate: widget.carRental.returnDate.toLocal(),
                returnLocation: widget.carRental.returnLocation,
                bookingNumber: widget.carRental.bookingNumber,
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
                onPressed: _isLoading ? null : _showDeleteConfirmation,
                icon: const Icon(Icons.delete_outline),
                label: const Text("Delete Car Rental"),
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

  void _handleFormSubmit(CarRentalFormData formData) {
    _submit();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = "Please fill in all required fields";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final formData = _formKey.currentState!.getFormData();
      final command = UpdateCarRental(
        id: widget.carRental.id,
        provider: formData.provider,
        pickUpDate: formData.pickUpDate,
        pickUpLocation: formData.pickUpLocation,
        returnDate: formData.returnDate,
        returnLocation: formData.returnLocation,
        bookingNumber: formData.bookingNumber,
      );

      await updateCarRental(command: command);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Car rental updated successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to update car rental: $e";
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
          title: const Text('Delete Car Rental'),
          content: Text('Are you sure you want to delete "${widget.carRental.provider}" car rental? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCarRental();
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

  void _deleteCarRental() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await deleteCarRental(carRentalId: widget.carRental.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Car rental deleted successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to delete car rental: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
