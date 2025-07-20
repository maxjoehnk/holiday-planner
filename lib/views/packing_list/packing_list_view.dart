import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/packing_list.dart';
import 'package:holiday_planner/src/rust/commands/delete_packing_list_entry.dart';
import 'package:holiday_planner/src/rust/models.dart';

import 'edit_packing_list_entry.dart';
import 'conditions.dart';

class PackingListView extends StatefulWidget {
  const PackingListView({super.key});

  @override
  State<PackingListView> createState() => _PackingListViewState();
}

class _PackingListViewState extends State<PackingListView> {
  late StreamController<List<PackingListEntry>> _packingList;
  late Stream<List<PackingListEntry>>? _packingList$;

  @override
  void initState() {
    super.initState();
    _packingList = StreamController();
    _packingList$ = _packingList.stream;
    _fetch();
  }

  @override
  void activate() {
    super.activate();
    _fetch();
  }

  @override
  void reassemble() {
    super.reassemble();
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder(
            stream: _packingList$,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Error: ${snapshot.error}",
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return PackingList(snapshot.requireData, onRemove: _removeItem, onEdit: _editItem);
            }),
        Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: "packing_list_fab",
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text("Add Item"),
            ))
      ],
    );
  }

  void _fetch() {
    _packingList.addStream(getPackingList().asStream());
  }

  _addItem() async {
    await showAdaptiveDialog(
        context: context, builder: (context) => const EditItemDialog());
    _fetch();
  }

  _editItem(PackingListEntry item) async {
    await showAdaptiveDialog(
        context: context, builder: (context) => EditItemDialog(entry: item));
    _fetch();
  }

  _removeItem(PackingListEntry entry) async {
    await deletePackingListEntry(
        command: DeletePackingListEntry(id: entry.id));
    _fetch();
  }
}

class PackingList extends StatelessWidget {
  final List<PackingListEntry> packingList;
  final Function(PackingListEntry) onRemove;
  final Function(PackingListEntry) onEdit;

  const PackingList(this.packingList, {super.key, required this.onRemove, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    if (packingList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checklist_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              "No packing items",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              "Add items to your packing list to get started!",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView.separated(
        itemCount: packingList.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return PackingListItem(
              entry: packingList[index],
              onDelete: () => onRemove(packingList[index]),
              onEdit: () => onEdit(packingList[index])
          );
        },
      ),
    );
  }
}

class PackingListItem extends StatelessWidget {
  final PackingListEntry entry;
  final Function() onDelete;
  final Function() onEdit;

  const PackingListItem(
      {required this.entry, super.key, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (entry.description?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            entry.description!,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        // Show configured quantity if any configuration exists
                        if (_hasConfiguredQuantity(entry.quantity)) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatConfiguredQuantity(entry.quantity),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      color: colorScheme.error,
                    ),
                    tooltip: "Delete item",
                  ),
                ],
              ),
              if (entry.conditions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var condition in entry.conditions)
                      ConditionTag(condition: condition)
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _hasConfiguredQuantity(Quantity quantity) {
    return quantity.fixed != null || 
           quantity.perDay != null || 
           quantity.perNight != null;
  }

  String _formatConfiguredQuantity(Quantity quantity) {
    List<String> parts = [];
    
    if (quantity.fixed != null && quantity.fixed! > BigInt.zero) {
      parts.add("${quantity.fixed} fixed");
    }
    
    if (quantity.perDay != null && quantity.perDay! > BigInt.zero) {
      parts.add("${quantity.perDay} per day");
    }
    
    if (quantity.perNight != null && quantity.perNight! > BigInt.zero) {
      parts.add("${quantity.perNight} per night");
    }
    
    if (parts.isEmpty) {
      return "No quantity configured";
    }
    
    return parts.join(" + ");
  }
}
