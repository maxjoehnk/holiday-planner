import 'package:date_field/date_field.dart';
import 'package:flutter/material.dart';
import 'package:holiday_planner/widgets/form_field.dart';
import 'package:holiday_planner/widgets/required_fields_hint.dart';

class TrainFormData {
  final String trainNumber;
  final String departureStationName;
  final String departureStationCity;
  final String departureStationCountry;
  final String departurePlatform;
  final String arrivalStationName;
  final String arrivalStationCity;
  final String arrivalStationCountry;
  final String arrivalPlatform;
  final DateTime? departureTime;
  final DateTime? arrivalTime;

  TrainFormData({
    required this.trainNumber,
    required this.departureStationName,
    required this.departureStationCity,
    required this.departureStationCountry,
    required this.departurePlatform,
    required this.arrivalStationName,
    required this.arrivalStationCity,
    required this.arrivalStationCountry,
    required this.arrivalPlatform,
    required this.departureTime,
    required this.arrivalTime,
  });
}

class TrainForm extends StatefulWidget {
  final TrainFormData? initialData;
  final Function(TrainFormData) onSubmit;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onErrorDismiss;

  const TrainForm({
    super.key,
    this.initialData,
    required this.onSubmit,
    this.isLoading = false,
    this.errorMessage,
    this.onErrorDismiss,
  });

  @override
  State<TrainForm> createState() => TrainFormState();
}

class TrainFormState extends State<TrainForm> {
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

  DateTime? _departureTime;
  DateTime? _arrivalTime;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;

    _trainNumberController =
        TextEditingController(text: data?.trainNumber ?? '');
    _departureStationNameController =
        TextEditingController(text: data?.departureStationName ?? '');
    _departureStationCityController =
        TextEditingController(text: data?.departureStationCity ?? '');
    _departureStationCountryController =
        TextEditingController(text: data?.departureStationCountry ?? '');
    _departurePlatformController =
        TextEditingController(text: data?.departurePlatform ?? '');
    _arrivalStationNameController =
        TextEditingController(text: data?.arrivalStationName ?? '');
    _arrivalStationCityController =
        TextEditingController(text: data?.arrivalStationCity ?? '');
    _arrivalStationCountryController =
        TextEditingController(text: data?.arrivalStationCountry ?? '');
    _arrivalPlatformController =
        TextEditingController(text: data?.arrivalPlatform ?? '');

    _departureTime = data?.departureTime;
    _arrivalTime = data?.arrivalTime;
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
              "Train Details",
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextFormField(
              controller: _trainNumberController,
              textInputAction: TextInputAction.next,
              decoration: AppInputDecoration(
                  labelText: "Train Number",
                  hintText: "e.g., ICE 123",
                  icon: Icons.train),
            ),
            const SizedBox(height: 16),
            Text(
              "Departure",
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextFormField(
              controller: _departureStationNameController,
              textInputAction: TextInputAction.next,
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return "Please enter departure station name";
                }
                return null;
              },
              decoration: AppInputDecoration(
                labelText: "Station Name",
                required: true,
                hintText: "e.g., Berlin Hauptbahnhof",
                icon: Icons.departure_board,
              ),
            ),
            Row(
              spacing: 16,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _departureStationCityController,
                    textInputAction: TextInputAction.next,
                    decoration: AppInputDecoration(
                        labelText: "City",
                        hintText: "e.g., Berlin",
                        icon: Icons.location_city,
                        required: null),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _departureStationCountryController,
                    textInputAction: TextInputAction.next,
                    decoration: AppInputDecoration(
                        labelText: "Country",
                        hintText: "e.g., Germany",
                        icon: Icons.map,
                        required: null),
                  ),
                ),
              ],
            ),
            Row(
              spacing: 16,
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
                    decoration: AppInputDecoration(
                        labelText: "Platform",
                        hintText: "e.g., 12",
                        icon: Icons.numbers,
                        required: true),
                  ),
                ),
                Expanded(
                    child: DateTimeFormField(
                  decoration: AppInputDecoration(
                      labelText: "Departure Time",
                      hintText: null,
                      icon: Icons.access_time,
                      required: true),
                  hideDefaultSuffixIcon: true,
                  canClear: false,
                  validator: (value) {
                    if (value == null) {
                      return "Please select departure time";
                    }
                    return null;
                  },
                  initialValue: _departureTime,
                  onChanged: (DateTime? pickedDateTime) {
                    if (pickedDateTime == null) {
                      return;
                    }
                    setState(() {
                      _departureTime = pickedDateTime;
                      if (_arrivalTime != null &&
                          _arrivalTime!.isBefore(pickedDateTime)) {
                        _arrivalTime = null;
                      }
                    });
                  },
                )),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Arrival",
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextFormField(
              controller: _arrivalStationNameController,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter arrival station name";
                }
                return null;
              },
              decoration: AppInputDecoration(
                  labelText: "Station Name",
                  hintText: "e.g., Paris Gare du Nord",
                  icon: Icons.departure_board,
                  required: true),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _arrivalStationCityController,
                    textInputAction: TextInputAction.next,
                    decoration: AppInputDecoration(
                        labelText: "City",
                        hintText: "e.g., Paris",
                        icon: Icons.location_city,
                        required: null),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _arrivalStationCountryController,
                    textInputAction: TextInputAction.next,
                    decoration: AppInputDecoration(
                        labelText: "Country",
                        hintText: "e.g., France",
                        icon: Icons.map,
                        required: null),
                  ),
                ),
              ],
            ),
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
                    decoration: AppInputDecoration(
                        labelText: "Platform",
                        hintText: "e.g., 3",
                        icon: Icons.numbers,
                        required: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: DateTimeFormField(
                  decoration: AppInputDecoration(
                      labelText: "Arrival Time",
                      hintText: null,
                      icon: Icons.access_time,
                      required: true),
                  hideDefaultSuffixIcon: true,
                  canClear: false,
                  validator: (value) {
                    if (value == null) {
                      return "Please select arrival time";
                    }
                    return null;
                  },
                  initialValue: _arrivalTime,
                  initialPickerDateTime: _departureTime,
                  onChanged: (DateTime? pickedDateTime) {
                    if (pickedDateTime == null) {
                      return;
                    }
                    setState(() {
                      _arrivalTime = pickedDateTime;
                    });
                  },
                )),
              ],
            ),
            const SizedBox(height: 16),
            const RequiredFieldsHint()
          ],
        ),
      ),
    );
  }

  bool validate() {
    return _formKey.currentState!.validate() &&
        _departureTime != null &&
        _arrivalTime != null;
  }

  void submit() {
    if (validate()) {
      final formData = TrainFormData(
        trainNumber: _trainNumberController.text.trim(),
        departureStationName: _departureStationNameController.text.trim(),
        departureStationCity: _departureStationCityController.text.trim(),
        departureStationCountry: _departureStationCountryController.text.trim(),
        departurePlatform: _departurePlatformController.text.trim(),
        arrivalStationName: _arrivalStationNameController.text.trim(),
        arrivalStationCity: _arrivalStationCityController.text.trim(),
        arrivalStationCountry: _arrivalStationCountryController.text.trim(),
        arrivalPlatform: _arrivalPlatformController.text.trim(),
        departureTime: _departureTime,
        arrivalTime: _arrivalTime,
      );
      widget.onSubmit(formData);
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
    super.dispose();
  }
}
