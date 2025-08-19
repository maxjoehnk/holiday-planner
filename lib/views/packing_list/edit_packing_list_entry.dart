import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/packing_list.dart';
import 'package:holiday_planner/src/rust/commands/add_packing_list_entry.dart';
import 'package:holiday_planner/src/rust/commands/update_packing_list_entry.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/widgets/form_field.dart';

import 'condition_selector.dart';
import 'conditions.dart';
import 'temperature_selector.dart';
import 'trip_duration_selector.dart';
import 'tag_selector.dart';

class EditItemDialog extends StatefulWidget {
  final PackingListEntry? entry;

  const EditItemDialog({super.key, this.entry});

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _fixedQuantityController = TextEditingController();
  final TextEditingController _perDayController = TextEditingController();
  final TextEditingController _perNightController = TextEditingController();
  List<PackingListEntryCondition> conditions = [];
  List<String> _categorySuggestions = [];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.entry?.name ?? "";
    _descriptionController.text = widget.entry?.description ?? "";
    _categoryController.text = widget.entry?.category ?? "";
    _fixedQuantityController.text = widget.entry?.quantity.fixed?.toString() ?? "";
    _perDayController.text = widget.entry?.quantity.perDay?.toString() ?? "";
    _perNightController.text = widget.entry?.quantity.perNight?.toString() ?? "";
    conditions = widget.entry?.conditions ?? [];
    _loadCategorySuggestions();
  }

  void _loadCategorySuggestions() async {
    try {
      final items = await getPackingList();
      final names = items
          .map((e) => e.category)
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      if (mounted) {
        setState(() => _categorySuggestions = names);
      }
    } catch (_) {
      // ignore suggestion load errors quietly
    }
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
              decoration: AppInputDecoration(labelText: "Name",
                hintText: "Enter item name",
              icon: Icons.inventory_2_outlined),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: AppInputDecoration(labelText: "Description",
                  hintText: "Optional description",
                  icon: Icons.description_outlined),
            ),
            const SizedBox(height: 16),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                final q = textEditingValue.text.trim().toLowerCase();
                if (q.isEmpty) {
                  return _categorySuggestions;
                }
                return _categorySuggestions.where(
                      (option) => option.toLowerCase().contains(q),
                );
              },
              initialValue: TextEditingValue(text: _categoryController.text),
              onSelected: (String selection) {
                _categoryController.text = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                controller.text = _categoryController.text;
                controller.addListener(() {
                  if (_categoryController.text != controller.text) {
                    _categoryController.text = controller.text;
                  }
                });
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  onFieldSubmitted: (value) => onFieldSubmitted(),
                  decoration: AppInputDecoration(
                    labelText: "Category",
                    hintText: "Type to search or create",
                    icon: Icons.folder_outlined,
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                final theme = Theme.of(context);
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surface,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200, minWidth: 280),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  const Icon(Icons.folder_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(option, style: theme.textTheme.bodyMedium)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
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
                          decoration: AppInputDecoration(labelText: "Fixed", hintText: "0"),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _perDayController,
                          decoration: AppInputDecoration(labelText: "Per Day", hintText: "0"),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _perNightController,
                          decoration: AppInputDecoration(labelText: "Per Night", hintText: "0"),
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
      tag: (tag) => TagSelector(onSelect: onSelect, currentTagId: tag.tagId),
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
    String? category = _categoryController.text.trim();
    if (category.isEmpty) category = null;
    if (widget.entry == null) {
      await addPackingListEntry(
          command: AddPackingListEntry(
              name: name,
              description: description,
              conditions: conditions,
              quantity: quantity,
              category: category,
          ));
    }else {
      await updatePackingListEntry(command: UpdatePackingListEntry(
          id: widget.entry!.id,
          name: name,
          description: description,
          conditions: conditions,
          quantity: quantity,
          category: category,
      ));
    }
    Navigator.pop(context);
  }
}

