import 'package:date_field/date_field.dart';
import 'package:flutter/material.dart';
import 'package:holiday_planner/widgets/form_field.dart';
import 'package:holiday_planner/widgets/required_fields_hint.dart';
import 'package:uuid/uuid.dart';

class CarRentalFormData {
  final String provider;
  final String pickUpLocation;
  final DateTime pickUpDate;
  final DateTime returnDate;
  final String? returnLocation;
  final String? bookingNumber;
  final UuidValue? id;
  final UuidValue? tripId;

  CarRentalFormData({
    required this.provider,
    required this.pickUpLocation,
    required this.pickUpDate,
    required this.returnDate,
    this.returnLocation,
    this.bookingNumber,
    this.id,
    this.tripId,
  });
}

class CarRentalForm extends StatefulWidget {
  final CarRentalFormData? initialData;
  final Function(CarRentalFormData) onSubmit;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onErrorDismiss;

  const CarRentalForm({
    super.key,
    this.initialData,
    required this.onSubmit,
    this.isLoading = false,
    this.errorMessage,
    this.onErrorDismiss,
  });

  @override
  State<CarRentalForm> createState() => CarRentalFormState();
}

class CarRentalFormState extends State<CarRentalForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _providerController;
  late final TextEditingController _pickUpLocationController;
  late final TextEditingController _returnLocationController;
  late final TextEditingController _bookingNumberController;
  late DateTime? _pickUpDate;
  late DateTime? _returnDate;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;

    _providerController = TextEditingController(text: data?.provider ?? '');
    _pickUpLocationController = TextEditingController(text: data?.pickUpLocation ?? '');
    _returnLocationController = TextEditingController(text: data?.returnLocation ?? '');
    _bookingNumberController = TextEditingController(text: data?.bookingNumber ?? '');
    _pickUpDate = data?.pickUpDate;
    _returnDate = data?.returnDate;
  }

  @override
  void dispose() {
    _providerController.dispose();
    _pickUpLocationController.dispose();
    _returnLocationController.dispose();
    _bookingNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            if (widget.errorMessage != null) ...[
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
                        widget.errorMessage!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onErrorDismiss,
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
            TextFormField(
              controller: _providerController,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter a provider";
                }
                return null;
              },
              decoration: AppInputDecoration(
                labelText: "Provider",
                hintText: "e.g., Sixt, Hertz, Avis",
                required: true,
              ),
            ),
            TextFormField(
              controller: _pickUpLocationController,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter a pick up location";
                }
                return null;
              },
              decoration: AppInputDecoration(
                labelText: "Pick Up Location",
                hintText: "e.g., JFK Airport, Downtown Office",
                required: true,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: DateTimeFormField(
                    decoration: AppInputDecoration(
                      labelText: "Pick Up Date & Time",
                      required: true,
                      icon: Icons.calendar_today,
                    ),
                    initialValue: _pickUpDate,
                    canClear: false,
                    hideDefaultSuffixIcon: true,
                    onChanged: (DateTime? pickedDateTime) {
                      if (pickedDateTime == null) {
                        return;
                      }

                      setState(() {
                        _pickUpDate = pickedDateTime;
                        if (_returnDate != null && _returnDate!.isBefore(pickedDateTime)) {
                          _returnDate = null;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DateTimeFormField(
                    decoration: AppInputDecoration(
                      labelText: "Return Date & Time",
                      required: true,
                      icon: Icons.calendar_today,
                    ),
                    initialValue: _returnDate,
                    hideDefaultSuffixIcon: true,
                    canClear: false,
                    onChanged: (DateTime? pickedDateTime) {
                      if (pickedDateTime == null) {
                        return;
                      }

                      setState(() {
                        _returnDate = pickedDateTime;
                      });
                    },
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _returnLocationController,
              textInputAction: TextInputAction.next,
              decoration: AppInputDecoration(
                labelText: "Return Location",
                hintText: "Leave empty if same as pick up location",
              ),
            ),
            TextFormField(
              controller: _bookingNumberController,
              textInputAction: TextInputAction.done,
              decoration: AppInputDecoration(
                labelText: "Booking Number",
                hintText: "e.g., CAR123456",
              ),
            ),
            const SizedBox(height: 16),
            const RequiredFieldsHint(),
          ],
        ),
      ),
    );
  }

  bool validate() {
    return _formKey.currentState!.validate() && _pickUpDate != null && _returnDate != null;
  }

  CarRentalFormData getFormData() {
    return CarRentalFormData(
      provider: _providerController.text.trim(),
      pickUpLocation: _pickUpLocationController.text.trim(),
      pickUpDate: _pickUpDate!,
      returnDate: _returnDate!,
      returnLocation: _returnLocationController.text.trim().isEmpty
          ? null
          : _returnLocationController.text.trim(),
      bookingNumber: _bookingNumberController.text.trim().isEmpty
          ? null
          : _bookingNumberController.text.trim(),
      id: widget.initialData?.id,
      tripId: widget.initialData?.tripId,
    );
  }

  void submit() {
    if (validate()) {
      widget.onSubmit(getFormData());
    }
  }
}
