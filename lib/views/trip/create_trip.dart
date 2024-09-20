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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Trip"),
        actions: [
          FilledButton(
            onPressed: _submit,
            child: const Text("Create"),
          ),
          const SizedBox(width: 8)
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _pickImage,
                  child: SizedBox(
                    height: 128,
                    width: double.infinity,
                    child: image != null
                        ? Image.file(
                            File(image!.path),
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.add_a_photo_outlined),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a name";
                  }
                  return null;
                },
                decoration: const InputDecoration(
                    labelText: "Name", border: OutlineInputBorder()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: InputDatePickerFormField(
                      initialDate: startDate,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 5)),
                      fieldLabelText: "Start Date",
                      onDateSubmitted: (value) =>
                          setState(() => startDate = value),
                    ),
                  ),
                  Container(width: 8),
                  Expanded(
                    child: InputDatePickerFormField(
                      initialDate: endDate,
                      firstDate: startDate ?? DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 5)),
                      fieldLabelText: "End Date",
                      onDateSubmitted: (value) =>
                          setState(() => endDate = value),
                    ),
                  ),
                  Container(width: 8),
                  IconButton(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_month_outlined))
                ],
              ),
            ),
          ],
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
