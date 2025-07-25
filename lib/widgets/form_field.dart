import 'package:flutter/material.dart';

class AppInputDecoration extends InputDecoration {
  AppInputDecoration({required String labelText, super.hintText, IconData? icon, bool? required}): super(
      labelText: "$labelText${required == true ? ' *' : ''}",
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      prefixIcon: icon == null ? null : Icon(icon),
      alignLabelWithHint: true,);
}
