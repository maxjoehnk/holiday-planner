import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/bookings.dart';
import 'package:holiday_planner/src/rust/commands/update_reservation.dart';
import 'package:holiday_planner/src/rust/models/bookings.dart';
import 'package:holiday_planner/widgets/date_time_picker.dart';

class EditReservationPage extends StatefulWidget {
  final Reservation reservation;

  const EditReservationPage({super.key, required this.reservation});

  @override
  State<EditReservationPage> createState() => _EditReservationPageState();
}

class _EditReservationPageState extends State<EditReservationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _addressController;
  late final TextEditingController _linkController;
  late final TextEditingController _bookingNumberController;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late ReservationCategory _selectedCategory;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reservation.title);
    _addressController = TextEditingController(text: widget.reservation.address ?? '');
    _linkController = TextEditingController(text: widget.reservation.link ?? '');
    _bookingNumberController = TextEditingController(text: widget.reservation.bookingNumber ?? '');
    _startDate = widget.reservation.startDate.toLocal();
    _endDate = widget.reservation.endDate?.toLocal();
    _selectedCategory = widget.reservation.category;
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _errorMessage = null),
                        icon: Icon(
                          Icons.close,
                          color: colorScheme.onErrorContainer,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                "Reservation Details",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a title";
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: "Title *",
                  hintText: "e.g., Restaurant Le Bernardin",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "Address",
                  hintText: "e.g., 155 West 51st Street, New York",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ReservationCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: "Category *",
                  border: OutlineInputBorder(),
                ),
                items: ReservationCategory.values.map((category) {
                  return DropdownMenuItem<ReservationCategory>(
                    value: category,
                    child: Row(
                      children: [
                        Icon(
                          category == ReservationCategory.restaurant
                              ? Icons.restaurant
                              : Icons.local_activity,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(category == ReservationCategory.restaurant
                            ? 'Restaurant'
                            : 'Activity'),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (ReservationCategory? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectStartDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Start Date & Time *",
                          border: const OutlineInputBorder(),
                          errorText: _startDate == null ? "Please select a start date and time" : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _startDate != null
                                    ? "${_startDate!.day}/${_startDate!.month}/${_startDate!.year} ${_startDate!.hour.toString().padLeft(2, '0')}:${_startDate!.minute.toString().padLeft(2, '0')}"
                                    : "Select date & time",
                                style: _startDate != null
                                    ? textTheme.bodyLarge
                                    : textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                              ),
                            ),
                            const Icon(Icons.access_time),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectEndDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "End Date & Time",
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _endDate != null
                                    ? "${_endDate!.day}/${_endDate!.month}/${_endDate!.year} ${_endDate!.hour.toString().padLeft(2, '0')}:${_endDate!.minute.toString().padLeft(2, '0')}"
                                    : "Select date & time",
                                style: _endDate != null
                                    ? textTheme.bodyLarge
                                    : textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                              ),
                            ),
                            const Icon(Icons.access_time),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _linkController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: "Website/Link",
                  hintText: "e.g., https://restaurant.com",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bookingNumberController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: "Booking Number",
                  hintText: "e.g., RES123456",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "* Required fields",
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _showDeleteConfirmation,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text("Delete Reservation"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? pickedTime = await selectDateTime(context, initialDate: _startDate);

    if (pickedTime == null) {
      return;
    }

    setState(() {
      _startDate = pickedTime;
      if (_endDate != null && _endDate!.isBefore(pickedTime)) {
        _endDate = null;
      }
    });
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? pickedTime = await selectDateTime(context, initialDate: _endDate ?? _startDate, startDate: _startDate);

    setState(() {
      _endDate = pickedTime;
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _startDate == null) {
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
      final command = UpdateReservation(
        id: widget.reservation.id,
        title: _titleController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate,
        link: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
        bookingNumber: _bookingNumberController.text.trim().isEmpty ? null : _bookingNumberController.text.trim(),
        category: _selectedCategory,
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

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _linkController.dispose();
    _bookingNumberController.dispose();
    super.dispose();
  }
}
