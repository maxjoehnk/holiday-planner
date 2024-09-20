import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';

enum Temperature { min, max }

class TemperatureSelector extends StatefulWidget {
  final Temperature threshold;
  final double? temperature;
  final Function(PackingListEntryCondition) onSelect;

  const TemperatureSelector({super.key, required this.onSelect, required this.threshold, this.temperature});

  @override
  State<TemperatureSelector> createState() => _TemperatureSelectorState();
}

class _TemperatureSelectorState extends State<TemperatureSelector> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.temperature?.toString() ?? "";
  }

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    return Dialog(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Text("Select Temperature", style: textTheme.titleLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controller,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: "Temperature"),
                  textInputAction: TextInputAction.send,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a temperature";
                    }
                    return null;
                  },
                ),
                OverflowBar(
                  children: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel")),
                    const SizedBox(height: 8),
                    FilledButton(onPressed: _onConfirm, child: Text(widget.temperature != null ? "Save" : "Add"))
                  ],
                )
              ],
            ),
          ),
        ));
  }

  _onConfirm() {
    Navigator.pop(context);
    var temperature = double.parse(_controller.text);
    var condition = widget.threshold == Temperature.min
        ? PackingListEntryCondition.minTemperature(temperature: temperature)
        : PackingListEntryCondition.maxTemperature(temperature: temperature);
    widget.onSelect(condition);
  }
}
