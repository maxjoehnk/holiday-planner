import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/bookings.dart';
import 'package:holiday_planner/src/rust/commands/add_reservation.dart';
import 'package:holiday_planner/src/rust/models/bookings.dart';
import 'package:holiday_planner/views/trip/bookings/reservation_form.dart';
import 'package:uuid/uuid.dart';

class AddReservationPage extends StatefulWidget {
  final UuidValue tripId;

  const AddReservationPage({super.key, required this.tripId});

  @override
  State<AddReservationPage> createState() => _AddReservationPageState();
}

class _AddReservationPageState extends State<AddReservationPage> {
  final GlobalKey<ReservationFormState> _formKey = GlobalKey<ReservationFormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Reservation"),
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
      body: ReservationForm(
        key: _formKey,
        initialData: ReservationFormData(
          title: '',
          startDate: DateTime.now(),
          category: ReservationCategory.restaurant,
          tripId: widget.tripId,
        ),
        onSubmit: _handleSubmit,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        onErrorDismiss: () => setState(() => _errorMessage = null),
      ),
    );
  }

  void _handleSubmit(ReservationFormData formData) {
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
      final command = AddReservation(
        tripId: widget.tripId,
        title: formData.title,
        address: formData.address,
        startDate: formData.startDate,
        endDate: formData.endDate,
        link: formData.link,
        bookingNumber: formData.bookingNumber,
        category: formData.category,
      );

      await addReservation(command: command);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation added successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to add reservation: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
