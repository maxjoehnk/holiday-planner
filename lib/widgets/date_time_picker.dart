import 'package:flutter/material.dart';

Future<DateTime?> selectDateTime(BuildContext context,
    {DateTime? initialDate, DateTime? startDate, DateTime? endDate}) async {
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: initialDate ?? DateTime.now(),
    firstDate: startDate ?? DateTime(2000),
    lastDate: endDate ?? DateTime(2100),
  );

  if (pickedDate == null) {
    return null;
  }

  if (!context.mounted) {
    return null;
  }

  final TimeOfDay? pickedTime = await showTimePicker(
    context: context,
    initialTime: initialDate != null
        ? TimeOfDay.fromDateTime(initialDate)
        : TimeOfDay.now(),
  );

  if (pickedTime == null) {
    return null;
  }

  final DateTime selectedTime = DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    pickedTime.hour,
    pickedTime.minute,
  );

  return selectedTime;
}
