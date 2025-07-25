import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/bookings.dart';
import 'package:holiday_planner/src/rust/commands/add_car_rental.dart';
import 'package:holiday_planner/views/trip/bookings/car_rental_form.dart';
import 'package:uuid/uuid.dart';

class AddCarRentalPage extends StatefulWidget {
  final UuidValue tripId;

  const AddCarRentalPage({super.key, required this.tripId});

  @override
  State<AddCarRentalPage> createState() => _AddCarRentalPageState();
}

class _AddCarRentalPageState extends State<AddCarRentalPage> {
  final _formKey = GlobalKey<CarRentalFormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Car Rental"),
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
      body: CarRentalForm(
        key: _formKey,
        initialData: CarRentalFormData(
          provider: '',
          pickUpLocation: '',
          pickUpDate: DateTime.now(),
          returnDate: DateTime.now().add(const Duration(days: 1)),
          tripId: widget.tripId,
        ),
        onSubmit: _handleFormSubmit,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        onErrorDismiss: () => setState(() => _errorMessage = null),
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
      final command = AddCarRental(
        tripId: widget.tripId,
        provider: formData.provider,
        pickUpDate: formData.pickUpDate,
        pickUpLocation: formData.pickUpLocation,
        returnDate: formData.returnDate,
        returnLocation: formData.returnLocation,
        bookingNumber: formData.bookingNumber,
      );

      await addCarRental(command: command);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Car rental added successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to add car rental: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
