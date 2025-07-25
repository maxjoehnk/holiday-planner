import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/widgets/form_field.dart';

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
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.schedule,
                      size: 20,
                      color: colorScheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.threshold == TripDuration.min 
                          ? "Min Trip Duration" 
                          : "Max Trip Duration",
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                widget.threshold == TripDuration.min 
                    ? "Set the minimum trip duration for this item to be included in your packing list."
                    : "Set the maximum trip duration for this item to be included in your packing list.",
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _controller,
                autofocus: true,
                decoration: AppInputDecoration(
                  labelText: "Duration (days)",
                  hintText: "Enter number of days",
                  icon: Icons.schedule,
                ),
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a duration";
                  }
                  if (int.tryParse(value) == null) {
                    return "Please enter a valid number";
                  }
                  var duration = int.parse(value);
                  if (duration <= 0) {
                    return "Duration must be greater than 0";
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _onConfirm(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _onConfirm,
                    child: Text(widget.length != null ? "Save" : "Add"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _onConfirm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    Navigator.pop(context);
    var length = int.parse(_controller.text);
    var condition = widget.threshold == TripDuration.min
        ? PackingListEntryCondition.minTripDuration(length: length)
        : PackingListEntryCondition.maxTripDuration(length: length);
    widget.onSelect(condition);
  }
}
