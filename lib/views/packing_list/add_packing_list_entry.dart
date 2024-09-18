import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/commands/add_packing_list_entry.dart';
import 'package:holiday_planner/src/rust/models.dart';

import 'conditions.dart';

class AddItemDialog extends StatefulWidget {
  const AddItemDialog({super.key});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _fixedQuantityController = TextEditingController();
  final TextEditingController _perDayController = TextEditingController();
  final TextEditingController _perNightController = TextEditingController();
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
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), labelText: "Description"),
            ),
            const SizedBox(height: 16),
            //Flexible(
            //  child: Row(
            //    mainAxisSize: MainAxisSize.min,
            //    crossAxisAlignment: CrossAxisAlignment.start,
            //    children: [
            //      TextFormField(
            //        controller: _fixedQuantityController,
            //        decoration: const InputDecoration(
            //            border: OutlineInputBorder(), labelText: "Quantity"),
            //        keyboardType: TextInputType.number,
            //      ),
            //      TextFormField(
            //        controller: _perDayController,
            //        decoration: const InputDecoration(
            //            border: OutlineInputBorder(), labelText: "per Day"),
            //        keyboardType: TextInputType.number,
            //      ),
            //      TextFormField(
            //        controller: _perNightController,
            //        decoration: const InputDecoration(
            //            border: OutlineInputBorder(), labelText: "per Night"),
            //        keyboardType: TextInputType.number,
            //      ),
            //    ],
            //  ),
            //),
            const SizedBox(height: 16),
            TextButton.icon(
                onPressed: () => showDialog(
                    context: context,
                    builder: (context) => ConditionSelector(
                        onSelect: (condition) =>
                            setState(() => conditions.add(condition)))),
                icon: const Icon(Icons.add),
                label: const Text("Add Condition")),
            const SizedBox(height: 4),
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
            const SizedBox(height: 4),
            OverflowBar(
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
    String? description = _descriptionController.text;
    if (description.isEmpty) {
      description = null;
    }
    await addPackingListEntry(
        command: AddPackingListEntry(
            name: name, description: description, conditions: conditions, quantity: const Quantity()));
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
                  condition: WeatherCondition.rain, minProbability: 0.5)),
        ),
      ],
    ));
  }

  _onSelect(BuildContext context, PackingListEntryCondition condition) {
    Navigator.pop(context);
    onSelect(condition);
  }
}
