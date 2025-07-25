import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/bookings.dart';
import 'package:holiday_planner/src/rust/commands/update_reservation.dart';
import 'package:holiday_planner/src/rust/models/bookings.dart';
import 'package:holiday_planner/views/trip/bookings/reservation_form.dart';

class EditReservationPage extends StatefulWidget {
  final Reservation reservation;

  const EditReservationPage({super.key, required this.reservation});

  @override
  State<EditReservationPage> createState() => _EditReservationPageState();
}

class _EditReservationPageState extends State<EditReservationPage> {
  final GlobalKey<ReservationFormState> _formKey = GlobalKey<ReservationFormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Reservation"),
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
            child: ReservationForm(
              key: _formKey,
              initialData: ReservationFormData(
                id: widget.reservation.id,
                title: widget.reservation.title,
                address: widget.reservation.address,
                startDate: widget.reservation.startDate.toLocal(),
                endDate: widget.reservation.endDate?.toLocal(),
                link: widget.reservation.link,
                bookingNumber: widget.reservation.bookingNumber,
                category: widget.reservation.category,
              ),
              onSubmit: _handleSubmit,
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
                label: const Text("Delete Reservation"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
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
      final command = UpdateReservation(
        id: widget.reservation.id,
        title: formData.title,
        address: formData.address,
        startDate: formData.startDate,
        endDate: formData.endDate,
        link: formData.link,
        bookingNumber: formData.bookingNumber,
        category: formData.category,
      );

      await updateReservation(command: command);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation updated successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to update reservation: $e";
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
          title: const Text('Delete Reservation'),
          content: Text('Are you sure you want to delete "${widget.reservation.title}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteReservation();
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

  void _deleteReservation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await deleteReservation(reservationId: widget.reservation.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation deleted successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to delete reservation: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
