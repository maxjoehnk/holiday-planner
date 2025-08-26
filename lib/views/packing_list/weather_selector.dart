import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/l10n/app_localizations.dart';

Map<WeatherCondition, IconData> _weatherIcons = {
  WeatherCondition.sunny: Icons.wb_sunny,
  WeatherCondition.rain: Icons.water_drop,
  WeatherCondition.clouds: Icons.cloud,
  WeatherCondition.snow: Icons.snowing,
  WeatherCondition.thunderstorm: Icons.thunderstorm,
};

String _labelFor(WeatherCondition c, BuildContext context) {
  switch (c) {
    case WeatherCondition.sunny:
      return AppLocalizations.of(context)!.weatherSunny;
    case WeatherCondition.rain:
      return AppLocalizations.of(context)!.weatherRain;
    case WeatherCondition.clouds:
      return AppLocalizations.of(context)!.weatherCloudy;
    case WeatherCondition.snow:
      return AppLocalizations.of(context)!.weatherSnow;
    case WeatherCondition.thunderstorm:
      return AppLocalizations.of(context)!.weatherThunderstorm;
  }
}

class WeatherSelector extends StatefulWidget {
  final WeatherCondition? condition;
  final double? minProbability;
  final Function(PackingListEntryCondition) onSelect;

  const WeatherSelector({
    super.key, 
    required this.onSelect, 
    this.condition, 
    this.minProbability
  });

  @override
  State<WeatherSelector> createState() => _WeatherSelectorState();
}

class _WeatherSelectorState extends State<WeatherSelector> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();
  WeatherCondition _selectedCondition = WeatherCondition.rain;

  @override
  void initState() {
    super.initState();
    _selectedCondition = widget.condition ?? WeatherCondition.rain;
    _controller.text = widget.minProbability != null 
        ? (widget.minProbability! * 100).round().toString() 
        : "50";
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
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _weatherIcons[_selectedCondition],
                      size: 20,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.weatherConditionTitle,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.weatherConditionDescription,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.weatherConditionTitle,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: WeatherCondition.values.map((condition) {
                  final isSelected = condition == _selectedCondition;
                  return FilterChip(
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCondition = condition;
                        });
                      }
                    },
                    avatar: Icon(
                      _weatherIcons[condition],
                      size: 16,
                      color: isSelected 
                          ? colorScheme.onSecondaryContainer 
                          : colorScheme.onSurfaceVariant,
                    ),
                    label: Text(_labelFor(condition, context)),
                    backgroundColor: colorScheme.surface,
                    selectedColor: colorScheme.secondaryContainer,
                    checkmarkColor: colorScheme.onSecondaryContainer,
                    side: BorderSide(
                      color: isSelected 
                          ? colorScheme.secondaryContainer 
                          : colorScheme.outline,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _controller,
                autofocus: false,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.minimumProbabilityLabel,
                  hintText: AppLocalizations.of(context)!.minimumProbabilityHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.percent),
                  suffixText: "%",
                ),
                textInputAction: TextInputAction.done,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.enterProbabilityValidation;
                  }
                  final probability = double.tryParse(value);
                  if (probability == null) {
                    return AppLocalizations.of(context)!.enterValidNumberValidation;
                  }
                  if (probability < 0 || probability > 100) {
                    return AppLocalizations.of(context)!.probabilityRangeValidation;
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
                    child: Text(widget.condition != null ? AppLocalizations.of(context)!.save : AppLocalizations.of(context)!.add),
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
    final probability = double.parse(_controller.text) / 100.0;
    final condition = PackingListEntryCondition.weather(
      condition: _selectedCondition,
      minProbability: probability,
    );
    widget.onSelect(condition);
  }
}
