import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/bookings.dart';
import 'package:holiday_planner/src/rust/commands/update_car_rental.dart';
import 'package:holiday_planner/src/rust/models/bookings.dart';
import 'package:holiday_planner/widgets/date_time_picker.dart';

class EditCarRentalPage extends StatefulWidget {
  final CarRental carRental;

  const EditCarRentalPage({super.key, required this.carRental});

  @override
  State<EditCarRentalPage> createState() => _EditCarRentalPageState();
}

class _EditCarRentalPageState extends State<EditCarRentalPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _providerController;
  late final TextEditingController _pickUpLocationController;
  late final TextEditingController _returnLocationController;
  late final TextEditingController _bookingNumberController;
  late DateTime? _pickUpDate;
  late DateTime? _returnDate;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _providerController =
        TextEditingController(text: widget.carRental.provider);
    _pickUpLocationController =
        TextEditingController(text: widget.carRental.pickUpLocation);
    _returnLocationController =
        TextEditingController(text: widget.carRental.returnLocation ?? '');
    _bookingNumberController =
        TextEditingController(text: widget.carRental.bookingNumber ?? '');
    _pickUpDate = widget.carRental.pickUpDate.toLocal();
    _returnDate = widget.carRental.returnDate.toLocal();
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

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
                "Car Rental Details",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _providerController,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a provider";
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: "Provider *",
                  hintText: "e.g., Sixt, Hertz, Avis",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pickUpLocationController,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a pick up location";
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: "Pick Up Location *",
                  hintText: "e.g., JFK Airport, Downtown Office",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectPickUpDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Pick Up Date & Time *",
                          border: const OutlineInputBorder(),
                          errorText: _pickUpDate == null
                              ? "Please select a pick up date and time"
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _pickUpDate != null
                                    ? "${_pickUpDate!.day}/${_pickUpDate!.month}/${_pickUpDate!.year} ${_pickUpDate!.hour.toString().padLeft(2, '0')}:${_pickUpDate!.minute.toString().padLeft(2, '0')}"
                                    : "Select date & time",
                                style: _pickUpDate != null
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
                      onTap: () => _selectReturnDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Return Date & Time *",
                          border: const OutlineInputBorder(),
                          errorText: _returnDate == null
                              ? "Please select a return date and time"
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _returnDate != null
                                    ? "${_returnDate!.day}/${_returnDate!.month}/${_returnDate!.year} ${_returnDate!.hour.toString().padLeft(2, '0')}:${_returnDate!.minute.toString().padLeft(2, '0')}"
                                    : "Select date & time",
                                style: _returnDate != null
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
                controller: _returnLocationController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "Return Location",
                  hintText: "Leave empty if same as pick up location",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bookingNumberController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: "Booking Number",
                  hintText: "e.g., CAR123456",
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
                  label: const Text("Delete Car Rental"),
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

  Future<void> _selectPickUpDate(BuildContext context) async {
    final DateTime? pickedDateTime =
        await selectDateTime(context, initialDate: _pickUpDate);

    if (pickedDateTime == null) {
      return;
    }

    setState(() {
      _pickUpDate = pickedDateTime;
      if (_returnDate != null && _returnDate!.isBefore(pickedDateTime)) {
        _returnDate = null;
      }
    });
  }

  Future<void> _selectReturnDate(BuildContext context) async {
    final DateTime? pickedDateTime = await selectDateTime(context,
        initialDate: _returnDate ?? _pickUpDate, startDate: _pickUpDate);

    if (pickedDateTime == null) {
      return;
    }

    setState(() {
      _returnDate = pickedDateTime;
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() ||
        _pickUpDate == null ||
        _returnDate == null) {
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
      final command = UpdateCarRental(
        id: widget.carRental.id,
        provider: _providerController.text.trim(),
        pickUpDate: _pickUpDate!,
        pickUpLocation: _pickUpLocationController.text.trim(),
        returnDate: _returnDate!,
        returnLocation: _returnLocationController.text.trim().isEmpty
            ? null
            : _returnLocationController.text.trim(),
        bookingNumber: _bookingNumberController.text.trim().isEmpty
            ? null
            : _bookingNumberController.text.trim(),
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

  @override
  void dispose() {
    _providerController.dispose();
    _pickUpLocationController.dispose();
    _returnLocationController.dispose();
    _bookingNumberController.dispose();
    super.dispose();
  }
}
