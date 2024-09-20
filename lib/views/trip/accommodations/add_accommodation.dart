import 'package:flutter/material.dart';
import 'package:holiday_planner/colors.dart';
import 'package:holiday_planner/src/rust/api/accommodations.dart';
import 'package:holiday_planner/src/rust/commands/add_trip_accommodation.dart';
import 'package:holiday_planner/views/trip/section_theme.dart';
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
  final TextEditingController _checkInTimeController = TextEditingController();
  final TextEditingController _checkOutTimeController = TextEditingController();
  DateTime checkInDate = DateTime.now();
  DateTime checkOutDate = DateTime.now();


  @override
  void initState() {
    super.initState();
    _checkInTimeController.addListener(() {
      var expected = TimeOfDay.fromDateTime(checkInDate).format(context);
      if (_checkInTimeController.text != expected) {
        _checkInTimeController.text = expected;
      }
    });
    _checkOutTimeController.addListener(() {
      var expected = TimeOfDay.fromDateTime(checkOutDate).format(context);
      if (_checkOutTimeController.text != expected) {
        _checkOutTimeController.text = expected;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _checkInTimeController.text = TimeOfDay.fromDateTime(checkInDate).format(context);
    _checkOutTimeController.text = TimeOfDay.fromDateTime(checkOutDate).format(context);
    return SectionTheme(
      color: ACCOMMODATIONS_COLOR,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Add Accommodation"),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
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
                  decoration:
                      const InputDecoration(labelText: "Name", border: OutlineInputBorder()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(children: [
                  Expanded(
                    child: InputDatePickerFormField(
                      initialDate: checkInDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      fieldLabelText: "Check-In Date",
                      onDateSubmitted: (value) => setState(() => checkInDate = value),
                    ),
                  ),
                  Container(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _checkInTimeController,
                      onTap: () => _selectCheckInTime(checkInDate),
                      decoration: const InputDecoration(
                          labelText: "Check-In Time", border: OutlineInputBorder()),
                    ),
                  ),
                  Container(width: 8),
                  IconButton(
                      onPressed: () => _selectCheckInDate(),
                      icon: const Icon(Icons.calendar_month_outlined))
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(children: [
                  Expanded(
                    child: InputDatePickerFormField(
                      initialDate: checkOutDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      fieldLabelText: "Check-Out Date",
                      onDateSubmitted: (value) => setState(() => checkOutDate = value),
                    ),
                  ),
                  Container(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _checkOutTimeController,
                      onTap: () => _selectCheckOutTime(checkOutDate),
                      decoration: const InputDecoration(
                          labelText: "Check-Out Time", border: OutlineInputBorder()),
                    ),
                  ),
                  Container(width: 8),
                  IconButton(
                      onPressed: () => _selectCheckOutDate(),
                      icon: const Icon(Icons.calendar_month_outlined))
                ]),
              ),
              const Spacer(),
              const Divider(),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(onPressed: _cancel, child: const Text("Cancel")),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text("Save"),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectCheckInDate() async {
    var date = await showDatePicker(
        context: context,
        initialDate: checkInDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365 * 5)));
    if (date == null) {
      return;
    }
    _selectCheckInTime(date.copyWith(hour: checkInDate.hour, minute: checkInDate.minute));
  }

  Future<void> _selectCheckInTime(DateTime date) async {
    var time =
        await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(date));
    if (time == null) {
      return;
    }

    var newDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    setState(() {
      checkInDate = newDate;
      _checkInTimeController.text = TimeOfDay.fromDateTime(checkInDate).format(context);
    });
  }

  Future<void> _selectCheckOutDate() async {
    var date = await showDatePicker(
        context: context,
        initialDate: checkOutDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365 * 5)));
    if (date == null) {
      return;
    }
    _selectCheckOutTime(date.copyWith(hour: checkOutDate.hour, minute: checkOutDate.minute));
  }

  Future<void> _selectCheckOutTime(DateTime date) async {
    var time =
    await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(date));
    if (time == null) {
      return;
    }

    var newDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    setState(() {
      checkOutDate = newDate;
      _checkOutTimeController.text = TimeOfDay.fromDateTime(checkOutDate).format(context);
    });
  }


  _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await addTripAccommodation(
        command: AddTripAccommodation(
      name: _nameController.text,
      tripId: widget.tripId,
      checkIn: checkInDate,
      checkOut: checkOutDate,
    ));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  _cancel() {
    Navigator.of(context).pop();
  }
}
