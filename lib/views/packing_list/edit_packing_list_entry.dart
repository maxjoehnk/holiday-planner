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
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
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
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.entry != null ? Icons.edit : Icons.add,
                    size: 20,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.entry != null ? "Edit Item" : "Add Item",
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: "Name",
                hintText: "Enter item name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.inventory_2_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Description",
                hintText: "Optional description",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.numbers,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Quantity",
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Set how many items to bring. These will be calculated based on your trip duration.",
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _fixedQuantityController,
                          decoration: InputDecoration(
                            labelText: "Fixed",
                            hintText: "0",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _perDayController,
                          decoration: InputDecoration(
                            labelText: "Per Day",
                            hintText: "0",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _perNightController,
                          decoration: InputDecoration(
                            labelText: "Per Night",
                            hintText: "0",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tune,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Conditions",
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => ConditionSelector(
                            onSelect: (condition) =>
                                setState(() => conditions.add(condition)),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("Add"),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  if (conditions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var (i, condition) in conditions.indexed)
                          ConditionTag(
                            condition: condition,
                            onRemove: () => setState(() => conditions.removeAt(i)),
                            onEdit: () => _editCondition(condition),
                          ),
                      ],
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "No conditions set. This item will appear in all trips.",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
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
                  onPressed: _onSave,
                  child: Text(widget.entry != null ? "Save" : "Add"),
                ),
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

