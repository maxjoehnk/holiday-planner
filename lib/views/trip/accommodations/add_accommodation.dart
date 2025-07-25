import 'package:flutter/material.dart';
import 'package:holiday_planner/date_format.dart';
import 'package:holiday_planner/src/rust/api/accommodations.dart';
import 'package:holiday_planner/src/rust/commands/add_trip_accommodation.dart';
import 'package:holiday_planner/widgets/accommodation_summary_card.dart';
import 'package:holiday_planner/widgets/date_time_picker.dart';
import 'package:holiday_planner/widgets/form_field.dart';
import 'package:uuid/uuid.dart';

class AddAccommodation extends StatefulWidget {
  final UuidValue tripId;

  const AddAccommodation({super.key, required this.tripId});

  @override
  State<AddAccommodation> createState() => _AddAccommodationState();
}

class _AddAccommodationState extends State<AddAccommodation> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  DateTime checkInDate = DateTime.now();
  DateTime checkOutDate = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    checkInDate =
        DateTime(checkInDate.year, checkInDate.month, checkInDate.day, 15, 0);
    checkOutDate = DateTime(
        checkOutDate.year, checkOutDate.month, checkOutDate.day, 11, 0);
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Accommodation"),
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
                "Accommodation Details",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a name";
                  }
                  return null;
                },
                decoration: AppInputDecoration(
                  labelText: "Name",
                  hintText: "Hotel, Airbnb, etc.",
                  icon: Icons.hotel_outlined,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                textInputAction: TextInputAction.next,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Address (Optional)",
                  hintText: "Street address or location",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Check-in & Check-out",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildDateTimeCard(
                context,
                title: "Check-in",
                subtitle: "When you'll arrive",
                icon: Icons.login,
                dateTime: checkInDate,
                onDateTimeChanged: (newDateTime) {
                  setState(() {
                    checkInDate = newDateTime;
                  });
                },
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              _buildDateTimeCard(
                context,
                title: "Check-out",
                subtitle: "When you'll leave",
                icon: Icons.logout,
                dateTime: checkOutDate,
                onDateTimeChanged: (newDateTime) {
                  setState(() {
                    checkOutDate = newDateTime;
                  });
                },
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              AccommodationSummaryCard(
                  checkInDate: checkInDate, checkOutDate: checkOutDate),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required DateTime dateTime,
    required Function(DateTime) onDateTimeChanged,
    required Color color,
  }) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _selectDateTime(dateTime, onDateTimeChanged),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatDate(dateTime),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatTime(dateTime),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateTime(DateTime currentDateTime, Function(DateTime) onChanged) async {
    final DateTime? newDateTime = await selectDateTime(context, initialDate: currentDateTime);

    if (newDateTime == null) {
      return;
    }

    onChanged(newDateTime);
  }

  _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (checkOutDate.isBefore(checkInDate)) {
      setState(() {
        _errorMessage = "Check-out date must be after check-in date";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await addTripAccommodation(
        command: AddTripAccommodation(
          name: _nameController.text,
          address:
              _addressController.text.isEmpty ? null : _addressController.text,
          tripId: widget.tripId,
          checkIn: checkInDate,
          checkOut: checkOutDate,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to add accommodation: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }
}
