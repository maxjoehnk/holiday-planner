import 'package:flutter/material.dart';

class AppInputDecoration extends InputDecoration {
  AppInputDecoration(String label,
      {super.hintText, IconData? icon, bool? required}): super(
      labelText: "$label${required == true ? ' *' : ''}",
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      prefixIcon: icon == null ? null : Icon(icon),
      alignLabelWithHint: true,);
}
