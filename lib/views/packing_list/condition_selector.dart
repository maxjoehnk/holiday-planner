import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';

import 'trip_duration_selector.dart';
import 'temperature_selector.dart';

class ConditionSelector extends StatelessWidget {
  final Function(PackingListEntryCondition) onSelect;

  const ConditionSelector({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Dialog(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text("Min Trip Duration"),
              onTap: () => _onSelect(context,
                  const PackingListEntryCondition.minTripDuration(length: 1)),
            ),
            ListTile(
              title: const Text("Max Trip Duration"),
              onTap: () => _onSelect(context,
                  const PackingListEntryCondition.maxTripDuration(length: 1)),
            ),
            ListTile(
              title: const Text("Min Temperature"),
              onTap: () => _onSelect(context,
                  const PackingListEntryCondition.minTemperature(temperature: 20)),
            ),
            ListTile(
              title: const Text("Max Temperature"),
              onTap: () => _onSelect(context,
                  const PackingListEntryCondition.maxTemperature(temperature: 0)),
            ),
            ListTile(
              title: const Text("Weather"),
              onTap: () => _onSelect(
                  context,
                  const PackingListEntryCondition.weather(
                      condition: WeatherCondition.rain, minProbability: 0.5)),
            ),
          ],
        ));
  }

  _onSelect(BuildContext context, PackingListEntryCondition condition) async {
    var nextDialog = condition.map(
      minTripDuration: (_) => TripDurationSelector(onSelect: onSelect, threshold: TripDuration.min),
      maxTripDuration: (_) => TripDurationSelector(onSelect: onSelect, threshold: TripDuration.max),
      minTemperature: (_) => TemperatureSelector(onSelect: onSelect, threshold: Temperature.min),
      maxTemperature: (_) => TemperatureSelector(onSelect: onSelect, threshold: Temperature.max),
      weather: (_) => throw UnimplementedError(),
      tag: (_) => throw UnimplementedError(),
    );
    Navigator.pop(context);
    showDialog(context: context, builder: (context) => nextDialog);
  }
}
