import 'dart:io';

import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/commands/create_trip.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:image_picker/image_picker.dart';

import 'trip_view.dart';

class CreateTripView extends StatefulWidget {
  const CreateTripView({super.key});

  @override
  State<CreateTripView> createState() => _CreateTripViewState();
}

class _CreateTripViewState extends State<CreateTripView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker picker = ImagePicker();
  DateTime? startDate;
  DateTime? endDate;
  XFile? image;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Trip"),
        centerTitle: true,
        elevation: 0,
        actions: [
          FilledButton(
            onPressed: _submit,
            child: const Text("Create"),
          ),
          const SizedBox(width: 16)
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Image Card
              Card(
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: image != null
                        ? Image.file(
                            File(image!.path),
                            fit: BoxFit.cover,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primaryContainer,
                                  colorScheme.secondaryContainer,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 48,
                                  color: colorScheme.onPrimaryContainer.withOpacity(0.6),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Add Header Image",
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Trip Name Field
              Text(
                "Trip Details",
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
                decoration: const InputDecoration(
                  labelText: "Trip Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.luggage),
                ),
              ),
              const SizedBox(height: 24),
              
              // Date Selection Section
              Text(
                "Travel Dates",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InputDatePickerFormField(
                      initialDate: startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      fieldLabelText: "Start Date",
                      onDateSubmitted: (value) => setState(() => startDate = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InputDatePickerFormField(
                      initialDate: endDate,
                      firstDate: startDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      fieldLabelText: "End Date",
                      onDateSubmitted: (value) => setState(() => endDate = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Date Range Picker Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text("Select Date Range"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    var dateTimeRange = await showDateRangePicker(
        context: context,
        initialDateRange: startDate != null && endDate != null
            ? DateTimeRange(start: startDate!, end: endDate!)
            : null,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365 * 5)));
    if (dateTimeRange == null) {
      return;
    }

    setState(() {
      startDate = dateTimeRange.start;
      endDate = dateTimeRange.end;
    });
  }

  _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    var trip = await createTrip(
        command: CreateTrip(
            name: _nameController.text,
            startDate: startDate!,
            endDate: endDate!,
            headerImage: await image?.readAsBytes()));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TripView(tripId: trip.id),
      ),
    );
  }

  _pickImage() async {
    var pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage == null) {
      return;
    }
    setState(() {
      image = pickedImage;
    });
  }
}
