import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/transits.dart';
import 'package:holiday_planner/src/rust/commands/update_train.dart';
import 'package:holiday_planner/src/rust/models/transits.dart';
import 'package:holiday_planner/widgets/date_time_picker.dart';
import 'package:uuid/uuid.dart';

class EditTrainPage extends StatefulWidget {
  final Train train;
  final UuidValue trainId; // We need the ID for updating, but Train model doesn't include it

  const EditTrainPage({super.key, required this.train, required this.trainId});

  @override
  State<EditTrainPage> createState() => _EditTrainPageState();
}

class _EditTrainPageState extends State<EditTrainPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _trainNumberController;
  late final TextEditingController _departureStationNameController;
  late final TextEditingController _departureStationCityController;
  late final TextEditingController _departureStationCountryController;
  late final TextEditingController _departurePlatformController;
  late final TextEditingController _arrivalStationNameController;
  late final TextEditingController _arrivalStationCityController;
  late final TextEditingController _arrivalStationCountryController;
  late final TextEditingController _arrivalPlatformController;
  late final TextEditingController _seatController;
  late final TextEditingController _bookingNumberController;
  
  late DateTime? _departureTime;
  late DateTime? _arrivalTime;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Note: train_number, seat, and booking_number are not available in the current Train model
    // These fields will be empty but can still be edited
    _trainNumberController = TextEditingController(text: '');
    _departureStationNameController = TextEditingController(text: widget.train.departure.name);
    _departureStationCityController = TextEditingController(text: widget.train.departure.city ?? '');
    _departureStationCountryController = TextEditingController(text: widget.train.departure.country ?? '');
    _departurePlatformController = TextEditingController(text: widget.train.departure.scheduledPlatform);
    _arrivalStationNameController = TextEditingController(text: widget.train.arrival.name);
    _arrivalStationCityController = TextEditingController(text: widget.train.arrival.city ?? '');
    _arrivalStationCountryController = TextEditingController(text: widget.train.arrival.country ?? '');
    _arrivalPlatformController = TextEditingController(text: widget.train.arrival.scheduledPlatform);
    _seatController = TextEditingController(text: '');
    _bookingNumberController = TextEditingController(text: '');
    
    _departureTime = widget.train.scheduledDepartureTime.toLocal();
    _arrivalTime = widget.train.scheduledArrivalTime.toLocal();
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Train"),
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
              
              // Train Details Section
              Text(
                "Train Details",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _trainNumberController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "Train Number",
                  hintText: "e.g., ICE 123",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _seatController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "Seat",
                  hintText: "e.g., Car 5, Seat 12A",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bookingNumberController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "Booking Number",
                  hintText: "e.g., TRN123456",
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Departure Section
              Text(
                "Departure",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _departureStationNameController,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter departure station name";
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: "Station Name *",
                  hintText: "e.g., Berlin Hauptbahnhof",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _departureStationCityController,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter city";
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: "City *",
                        hintText: "e.g., Berlin",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _departureStationCountryController,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter country";
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: "Country *",
                        hintText: "e.g., Germany",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _departurePlatformController,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter platform";
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: "Platform *",
                        hintText: "e.g., 12",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDepartureTime(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Departure Time *",
                          border: const OutlineInputBorder(),
                          errorText: _departureTime == null
                              ? "Please select departure time"
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _departureTime != null
                                    ? "${_departureTime!.day}/${_departureTime!.month}/${_departureTime!.year} ${_departureTime!.hour.toString().padLeft(2, '0')}:${_departureTime!.minute.toString().padLeft(2, '0')}"
                                    : "Select time",
                                style: _departureTime != null
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
              
              const SizedBox(height: 32),
              
              // Arrival Section
              Text(
                "Arrival",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _arrivalStationNameController,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter arrival station name";
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: "Station Name *",
                  hintText: "e.g., Paris Gare du Nord",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _arrivalStationCityController,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter city";
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: "City *",
                        hintText: "e.g., Paris",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _arrivalStationCountryController,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter country";
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: "Country *",
                        hintText: "e.g., France",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _arrivalPlatformController,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter platform";
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: "Platform *",
                        hintText: "e.g., 3",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectArrivalTime(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Arrival Time *",
                          border: const OutlineInputBorder(),
                          errorText: _arrivalTime == null
                              ? "Please select arrival time"
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _arrivalTime != null
                                    ? "${_arrivalTime!.day}/${_arrivalTime!.month}/${_arrivalTime!.year} ${_arrivalTime!.hour.toString().padLeft(2, '0')}:${_arrivalTime!.minute.toString().padLeft(2, '0')}"
                                    : "Select time",
                                style: _arrivalTime != null
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
              
              const SizedBox(height: 32),
              Text(
                "* Required fields",
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDepartureTime(BuildContext context) async {
    final DateTime? pickedDateTime =
        await selectDateTime(context, initialDate: _departureTime);

    if (pickedDateTime == null) {
      return;
    }

    setState(() {
      _departureTime = pickedDateTime;
      if (_arrivalTime != null && _arrivalTime!.isBefore(pickedDateTime)) {
        _arrivalTime = null;
      }
    });
  }

  Future<void> _selectArrivalTime(BuildContext context) async {
    final DateTime? pickedDateTime = await selectDateTime(context,
        initialDate: _arrivalTime ?? _departureTime, startDate: _departureTime);

    if (pickedDateTime == null) {
      return;
    }

    setState(() {
      _arrivalTime = pickedDateTime;
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _departureTime == null || _arrivalTime == null) {
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
      final command = UpdateTrain(
        id: widget.trainId,
        trainNumber: _trainNumberController.text.trim().isEmpty
            ? null
            : _trainNumberController.text.trim(),
        departureStationName: _departureStationNameController.text.trim(),
        departureStationCity: _departureStationCityController.text.trim(),
        departureStationCountry: _departureStationCountryController.text.trim(),
        departureScheduledPlatform: _departurePlatformController.text.trim(),
        arrivalStationName: _arrivalStationNameController.text.trim(),
        arrivalStationCity: _arrivalStationCityController.text.trim(),
        arrivalStationCountry: _arrivalStationCountryController.text.trim(),
        arrivalScheduledPlatform: _arrivalPlatformController.text.trim(),
        scheduledDepartureTime: _departureTime!,
        scheduledArrivalTime: _arrivalTime!,
      );

      await updateTrain(command: command);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Train booking updated successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to update train booking: $e";
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
          title: const Text('Delete Train Booking'),
          content: const Text('Are you sure you want to delete this train booking? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTrain();
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

  void _deleteTrain() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await deleteTrain(trainId: widget.trainId);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Train booking deleted successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to delete train booking: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _trainNumberController.dispose();
    _departureStationNameController.dispose();
    _departureStationCityController.dispose();
    _departureStationCountryController.dispose();
    _departurePlatformController.dispose();
    _arrivalStationNameController.dispose();
    _arrivalStationCityController.dispose();
    _arrivalStationCountryController.dispose();
    _arrivalPlatformController.dispose();
    _seatController.dispose();
    _bookingNumberController.dispose();
    super.dispose();
  }
}
