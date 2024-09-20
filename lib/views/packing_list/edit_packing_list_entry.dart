import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/packing_list.dart';
import 'package:holiday_planner/src/rust/commands/add_packing_list_entry.dart';
import 'package:holiday_planner/src/rust/commands/update_packing_list_entry.dart';
import 'package:holiday_planner/src/rust/models.dart';

import 'condition_selector.dart';
import 'conditions.dart';
import 'temperature_selector.dart';
import 'trip_duration_selector.dart';

class EditItemDialog extends StatefulWidget {
  final PackingListEntry? entry;

  const EditItemDialog({super.key, this.entry});

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _fixedQuantityController = TextEditingController();
  final TextEditingController _perDayController = TextEditingController();
  final TextEditingController _perNightController = TextEditingController();
  List<PackingListEntryCondition> conditions = [];


  @override
  void initState() {
    super.initState();
    _nameController.text = widget.entry?.name ?? "";
    _descriptionController.text = widget.entry?.description ?? "";
    _fixedQuantityController.text = widget.entry?.quantity.fixed?.toString() ?? "";
    _perDayController.text = widget.entry?.quantity.perDay?.toString() ?? "";
    _perNightController.text = widget.entry?.quantity.perNight?.toString() ?? "";
    conditions = widget.entry?.conditions ?? [];
  }

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
                        onRemove: () => setState(() => conditions.removeAt(i)),
                        onEdit: () => _editCondition(condition),
                    ),
                ]),
            const SizedBox(height: 4),
            OverflowBar(
              children: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Cancel")),
                const SizedBox(height: 8),
                FilledButton(onPressed: _onSave, child: Text(widget.entry != null ? "Save" : "Add"))
              ],
            )
          ],
        ),
      ),
    );
  }

  _editCondition(PackingListEntryCondition condition) {
    onSelect(c) {
      var index = conditions.indexOf(condition);
      setState(() => conditions[index] = c);
    }

    var nextDialog = condition.map(
      minTripDuration: (duration) => TripDurationSelector(onSelect: onSelect, threshold: TripDuration.min, length: duration.length),
      maxTripDuration: (duration) => TripDurationSelector(onSelect: onSelect, threshold: TripDuration.max, length: duration.length),
      minTemperature: (temperature) => TemperatureSelector(onSelect: onSelect, threshold: Temperature.min, temperature: temperature.temperature),
      maxTemperature: (temperature) => TemperatureSelector(onSelect: onSelect, threshold: Temperature.max, temperature: temperature.temperature),
      weather: (_) => throw UnimplementedError(),
      tag: (_) => throw UnimplementedError(),
    );

    showDialog(context: context, builder: (context) => nextDialog);
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
    var quantity = Quantity(
      perDay: BigInt.tryParse(_perDayController.text),
      perNight: BigInt.tryParse(_perNightController.text),
      fixed: BigInt.tryParse(_fixedQuantityController.text),
    );
    if (widget.entry == null) {
      await addPackingListEntry(
          command: AddPackingListEntry(
              name: name, description: description, conditions: conditions, quantity: quantity));
    }else {
      await updatePackingListEntry(command: UpdatePackingListEntry(
          id: widget.entry!.id,
          name: name,
          description: description,
          conditions: conditions,
          quantity: quantity,
      ));
    }
    Navigator.pop(context);
  }
}

