import 'package:date_field/date_field.dart';
import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models/bookings.dart';
import 'package:holiday_planner/widgets/form_field.dart';
import 'package:holiday_planner/widgets/required_fields_hint.dart';
import 'package:uuid/uuid.dart';

class ReservationFormData {
  final String title;
  final String? address;
  final DateTime startDate;
  final DateTime? endDate;
  final String? link;
  final String? bookingNumber;
  final ReservationCategory category;
  final UuidValue? id;
  final UuidValue? tripId;

  ReservationFormData({
    required this.title,
    this.address,
    required this.startDate,
    this.endDate,
    this.link,
    this.bookingNumber,
    required this.category,
    this.id,
    this.tripId,
  });
}

class ReservationForm extends StatefulWidget {
  final ReservationFormData? initialData;
  final Function(ReservationFormData) onSubmit;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onErrorDismiss;

  const ReservationForm({
    super.key,
    this.initialData,
    required this.onSubmit,
    this.isLoading = false,
    this.errorMessage,
    this.onErrorDismiss,
  });

  @override
  State<ReservationForm> createState() => ReservationFormState();
}

class ReservationFormState extends State<ReservationForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _addressController;
  late final TextEditingController _linkController;
  late final TextEditingController _bookingNumberController;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late ReservationCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;

    _titleController = TextEditingController(text: data?.title ?? '');
    _addressController = TextEditingController(text: data?.address ?? '');
    _linkController = TextEditingController(text: data?.link ?? '');
    _bookingNumberController =
        TextEditingController(text: data?.bookingNumber ?? '');
    _startDate = data?.startDate;
    _endDate = data?.endDate;
    _selectedCategory = data?.category ?? ReservationCategory.restaurant;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _linkController.dispose();
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
              "Reservation Details",
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter a title";
                }
                return null;
              },
              decoration: AppInputDecoration(
                labelText: "Title",
                hintText: "e.g., Restaurant Le Bernardin",
                required: true,
              ),
            ),
            TextFormField(
              controller: _addressController,
              textInputAction: TextInputAction.next,
              decoration: AppInputDecoration(
                labelText: "Address",
                hintText: "e.g., 155 West 51st Street, New York",
              ),
            ),
            DropdownButtonFormField<ReservationCategory>(
              value: _selectedCategory,
              decoration: AppInputDecoration(
                labelText: "Category",
                required: true,
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
            Row(
              children: [
                Expanded(
                    child: DateTimeFormField(
                  decoration: AppInputDecoration(
                      labelText: "Start Date & Time",
                      required: true,
                      icon: Icons.calendar_today),
                  initialValue: _startDate,
                  canClear: false,
                  hideDefaultSuffixIcon: true,
                  onChanged: (DateTime? pickedDateTime) {
                    if (pickedDateTime == null) {
                      return;
                    }

                    setState(() {
                      _startDate = pickedDateTime;
                      if (_endDate != null &&
                          _endDate!.isBefore(pickedDateTime)) {
                        _endDate = null;
                      }
                    });
                  },
                )),
                const SizedBox(width: 16),
                Expanded(
                    child: DateTimeFormField(
                  decoration: AppInputDecoration(
                      labelText: "End Date & Time", icon: Icons.calendar_today),
                  initialValue: _endDate,
                  hideDefaultSuffixIcon: true,
                  onChanged: (DateTime? pickedDateTime) {
                    if (pickedDateTime == null) {
                      return;
                    }

                    setState(() {
                      _endDate = pickedDateTime;
                    });
                  },
                )),
              ],
            ),
            TextFormField(
              controller: _linkController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.url,
              decoration: AppInputDecoration(
                labelText: "Website/Link",
                hintText: "e.g., https://restaurant.com",
              ),
            ),
            TextFormField(
              controller: _bookingNumberController,
              textInputAction: TextInputAction.done,
              decoration: AppInputDecoration(
                labelText: "Booking Number",
                hintText: "e.g., RES123456",
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
    return _formKey.currentState!.validate() && _startDate != null;
  }

  ReservationFormData getFormData() {
    return ReservationFormData(
      title: _titleController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      startDate: _startDate!,
      endDate: _endDate,
      link: _linkController.text.trim().isEmpty
          ? null
          : _linkController.text.trim(),
      bookingNumber: _bookingNumberController.text.trim().isEmpty
          ? null
          : _bookingNumberController.text.trim(),
      category: _selectedCategory,
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
