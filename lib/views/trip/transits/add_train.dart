import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/transits.dart';
import 'package:holiday_planner/src/rust/commands/add_train.dart';
import 'package:holiday_planner/widgets/date_time_picker.dart';
import 'package:uuid/uuid.dart';

class AddTrainPage extends StatefulWidget {
  final UuidValue tripId;

  const AddTrainPage({super.key, required this.tripId});

  @override
  State<AddTrainPage> createState() => _AddTrainPageState();
}

class _AddTrainPageState extends State<AddTrainPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _trainNumberController = TextEditingController();
  final TextEditingController _departureStationNameController = TextEditingController();
  final TextEditingController _departureStationCityController = TextEditingController();
  final TextEditingController _departureStationCountryController = TextEditingController();
  final TextEditingController _departurePlatformController = TextEditingController();
  final TextEditingController _arrivalStationNameController = TextEditingController();
  final TextEditingController _arrivalStationCityController = TextEditingController();
  final TextEditingController _arrivalStationCountryController = TextEditingController();
  final TextEditingController _arrivalPlatformController = TextEditingController();
  final TextEditingController _seatController = TextEditingController();
  final TextEditingController _bookingNumberController = TextEditingController();
  
  DateTime? _departureTime;
  DateTime? _arrivalTime;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Train"),
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
                      decoration: const InputDecoration(
                        labelText: "City",
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
                      decoration: const InputDecoration(
                        labelText: "Country",
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
                      decoration: const InputDecoration(
                        labelText: "City",
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
                      decoration: const InputDecoration(
                        labelText: "Country",
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
                "* Required fields (City and Country are optional)",
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
      final command = AddTrain(
        tripId: widget.tripId,
        trainNumber: _trainNumberController.text.trim().isEmpty
            ? null
            : _trainNumberController.text.trim(),
        departureStationName: _departureStationNameController.text.trim(),
        departureStationCity: _departureStationCityController.text.trim().isEmpty
            ? null
            : _departureStationCityController.text.trim(),
        departureStationCountry: _departureStationCountryController.text.trim().isEmpty
            ? null
            : _departureStationCountryController.text.trim(),
        departureScheduledPlatform: _departurePlatformController.text.trim(),
        arrivalStationName: _arrivalStationNameController.text.trim(),
        arrivalStationCity: _arrivalStationCityController.text.trim().isEmpty
            ? null
            : _arrivalStationCityController.text.trim(),
        arrivalStationCountry: _arrivalStationCountryController.text.trim().isEmpty
            ? null
            : _arrivalStationCountryController.text.trim(),
        arrivalScheduledPlatform: _arrivalPlatformController.text.trim(),
        scheduledDepartureTime: _departureTime!,
        scheduledArrivalTime: _arrivalTime!,
      );

      await addTrain(command: command);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Train booking added successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to add train booking: $e";
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
