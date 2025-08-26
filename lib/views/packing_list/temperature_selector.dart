import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/widgets/form_field.dart';
import 'package:holiday_planner/l10n/app_localizations.dart';

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
                      color: widget.threshold == Temperature.min 
                          ? colorScheme.errorContainer 
                          : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.thermostat,
                      size: 20,
                      color: widget.threshold == Temperature.min 
                          ? colorScheme.onErrorContainer 
                          : colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.threshold == Temperature.min 
                          ? AppLocalizations.of(context)!.temperatureSelectorMinTitle 
                          : AppLocalizations.of(context)!.temperatureSelectorMaxTitle,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                widget.threshold == Temperature.min 
                    ? AppLocalizations.of(context)!.temperatureSelectorMinDescription
                    : AppLocalizations.of(context)!.temperatureSelectorMaxDescription,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _controller,
                autofocus: true,
                decoration: AppInputDecoration(
                  labelText: AppLocalizations.of(context)!.temperatureFieldLabel,
                  hintText: AppLocalizations.of(context)!.temperatureFieldHint,
                  icon: widget.threshold == Temperature.min
                        ? Icons.thermostat 
                        : Icons.ac_unit,
                ),
                textInputAction: TextInputAction.done,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.temperatureValidationEmpty;
                  }
                  if (double.tryParse(value) == null) {
                    return AppLocalizations.of(context)!.temperatureValidationNaN;
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
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _onConfirm,
                    child: Text(widget.temperature != null ? "Save" : "Add"),
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
    var temperature = double.parse(_controller.text);
    var condition = widget.threshold == Temperature.min
        ? PackingListEntryCondition.minTemperature(temperature: temperature)
        : PackingListEntryCondition.maxTemperature(temperature: temperature);
    widget.onSelect(condition);
  }
}
