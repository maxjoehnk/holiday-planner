import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:holiday_planner/src/rust/commands/update_trip.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:image_picker/image_picker.dart';

class EditTripView extends StatefulWidget {
  final TripOverviewModel trip;

  const EditTripView({super.key, required this.trip});

  @override
  State<EditTripView> createState() => _EditTripViewState();
}

class _EditTripViewState extends State<EditTripView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final ImagePicker picker = ImagePicker();
  late DateTime? startDate;
  late DateTime? endDate;
  XFile? image;
  bool _isLoading = false;
  String? _errorMessage;
  Uint8List? _headerImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.trip.name);
    _headerImage = widget.trip.headerImage;

    getTrips().then((trips) {
      final tripDetails = trips.firstWhere((t) => t.id == widget.trip.id);
      setState(() {
        startDate = tripDetails.startDate.toLocal();
        endDate = tripDetails.endDate.toLocal();
      });
    }).catchError((error) {
      setState(() {
        _errorMessage = "Failed to load trip dates: $error";
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Trip"),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
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
                        : _headerImage != null
                            ? Image.memory(
                                _headerImage!,
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
                                      color: colorScheme.onPrimaryContainer
                                          .withOpacity(0.6),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Change Header Image",
                                      style: textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.onPrimaryContainer
                                            .withOpacity(0.8),
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
                      firstDate: DateTime.now()
                          .subtract(const Duration(days: 365 * 5)),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 5)),
                      fieldLabelText: "Start Date",
                      onDateSubmitted: (value) =>
                          setState(() => startDate = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InputDatePickerFormField(
                      initialDate: endDate,
                      firstDate: startDate ??
                          DateTime.now()
                              .subtract(const Duration(days: 365 * 5)),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 5)),
                      fieldLabelText: "End Date",
                      onDateSubmitted: (value) =>
                          setState(() => endDate = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
        firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
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

    if (startDate == null || endDate == null) {
      setState(() {
        _errorMessage = "Please select start and end dates";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Uint8List? headerImageBytes;
      if (image != null) {
        headerImageBytes = await image!.readAsBytes();
      } else {
        headerImageBytes = _headerImage;
      }

      final command = UpdateTrip(
        id: widget.trip.id,
        name: _nameController.text,
        startDate: startDate!,
        endDate: endDate!,
        headerImage: headerImageBytes,
      );

      await updateTrip(command: command);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
