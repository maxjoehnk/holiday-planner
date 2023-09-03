import 'package:flutter/material.dart';
import 'package:holiday_planner/ffi.dart';

import 'conditions.dart';

class AddItemDialog extends StatefulWidget {
  const AddItemDialog({super.key});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final TextEditingController _nameController = TextEditingController();
  List<PackingListEntryCondition> conditions = [];

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text("Add Item", style: textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), labelText: "Name"),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
                onPressed: () => showDialog(
                    context: context,
                    builder: (context) => ConditionSelector(
                        onSelect: (condition) =>
                            setState(() => conditions.add(condition)))),
                icon: const Icon(Icons.add),
                label: const Text("Add Condition")),
            Wrap(
                direction: Axis.horizontal,
                runSpacing: 8,
                spacing: 8,
                children: [
                  for (var (i, condition) in conditions.indexed)
                    ConditionTag(
                        condition: condition,
                        onRemove: () => setState(() => conditions.removeAt(i))),
                ]),
            ButtonBar(
              children: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Cancel")),
                FilledButton(onPressed: _onSave, child: const Text("Add"))
              ],
            )
          ],
        ),
      ),
    );
  }

  _onSave() async {
    var name = _nameController.text;
    if (name.isEmpty) {
      return;
    }
    await api.addPackingListEntry(
        command: AddPackingListEntry(
            name: name, conditions: conditions, quantity: Quantity()));
    Navigator.pop(context);
  }
}

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
                  condition: WeatherCondition.Rain, minProbability: 0.5)),
        ),
      ],
    ));
  }

  _onSelect(BuildContext context, PackingListEntryCondition condition) {
    Navigator.pop(context);
    onSelect(condition);
  }
}
