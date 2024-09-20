import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';

enum TripDuration { min, max }

class TripDurationSelector extends StatefulWidget {
  final TripDuration threshold;
  final int? length;
  final Function(PackingListEntryCondition) onSelect;

  const TripDurationSelector({super.key, required this.onSelect, required this.threshold, this.length});

  @override
  State<TripDurationSelector> createState() => _TripDurationSelectorState();
}

class _TripDurationSelectorState extends State<TripDurationSelector> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.length?.toString() ?? "";
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
                Text("Select Duration", style: textTheme.titleLarge),
                const SizedBox(height: 16),
                TextFormField(
                  autofocus: true,
                  controller: _controller,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: "Days"),
                  textInputAction: TextInputAction.send,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a duration";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                OverflowBar(
                  children: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel")),
                    const SizedBox(height: 8),
                    FilledButton(onPressed: _onConfirm, child: Text(widget.length != null ? "Save" : "Add"))
                  ],
                )
              ],
            ),
          ),
        ));
  }

  _onConfirm() {
    Navigator.pop(context);
    var length = int.parse(_controller.text);
    var condition = widget.threshold == TripDuration.min
        ? PackingListEntryCondition.minTripDuration(length: length)
        : PackingListEntryCondition.maxTripDuration(length: length);
    widget.onSelect(condition);
  }
}
