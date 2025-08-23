import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:date_field/date_field.dart';
import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:holiday_planner/src/rust/api/tags.dart';
import 'package:holiday_planner/src/rust/commands/update_trip.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/views/home.dart';
import 'package:holiday_planner/widgets/form_field.dart';
import 'package:holiday_planner/widgets/tag_selection_widget.dart';
import 'package:image_picker/image_picker.dart';

import 'web_image_search.dart';

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
  List<TagModel> selectedTags = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.trip.name);
    _headerImage = widget.trip.headerImage;
    startDate = widget.trip.startDate.toLocal();
    endDate = widget.trip.endDate.toLocal();

    getTripTags(tripId: widget.trip.id).then((tags) {
      setState(() {
        selectedTags = tags;
      });
    }).catchError((error) {
      setState(() {
        _errorMessage = "Failed to load tags: $error";
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
                                      color: colorScheme.onPrimaryContainer.withOpacity(0.6),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Change Header Image",
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
                decoration: AppInputDecoration(
                  labelText: "Trip Name",
                  icon: Icons.luggage,
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
                    child: DateTimeFormField(
                      mode: DateTimeFieldPickerMode.date,
                      initialValue: startDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      onChanged: (value) => setState(() => startDate = value),
                      decoration: AppInputDecoration(
                        labelText: "Start Date",
                        icon: Icons.calendar_month,
                      ),
                      hideDefaultSuffixIcon: true,
                      canClear: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DateTimeFormField(
                      mode: DateTimeFieldPickerMode.date,
                      initialValue: endDate,
                      firstDate:
                          startDate ?? DateTime.now().subtract(const Duration(days: 365 * 5)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      onChanged: (value) => setState(() => endDate = value),
                      decoration: AppInputDecoration(
                        labelText: "End Date",
                        icon: Icons.calendar_month,
                      ),
                      hideDefaultSuffixIcon: true,
                      canClear: false,
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

              // Tag Selection Section
              TagSelectionWidget(
                selectedTags: selectedTags,
                onTagsChanged: (tags) => setState(() => selectedTags = tags),
              ),
              const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _showDeleteConfirmation,
                icon: const Icon(Icons.delete_outline),
                label: const Text("Delete Trip"),
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
        tagIds: selectedTags.map((tag) => tag.id).toList(),
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

  _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Trip'),
          content: const Text(
              'Are you sure you want to delete this trip? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
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

    if (confirmed == true) {
      _deleteTrip();
    }
  }

  _deleteTrip() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await deleteTrip(tripId: widget.trip.id);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                settings: const RouteSettings(name: "/"),
                builder: (_) => const HomeView()), (route) => false);
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to delete trip: $e";
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
    final source = await showDialog<ImageSource?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Device Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Web Search'),
                onTap: () => Navigator.pop(context, null), // null indicates web search
              ),
            ],
          ),
        );
      },
    );

    if (source == ImageSource.gallery) {
      // Existing gallery picker logic
      var pickedImage = await picker.pickImage(source: source!);
      if (pickedImage == null) {
        return;
      }
      setState(() {
        image = pickedImage;
        _headerImage = null; // Clear the header image since we're using XFile
      });
    } else if (source == null) {
      // Web search was selected
      final webImage = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder: (context) => const WebImageSearchView(),
        ),
      );

      if (webImage != null) {
        setState(() {
          _headerImage = webImage;
          image = null; // Clear the XFile since we're using Uint8List directly
        });
      }
    }
  }
}
