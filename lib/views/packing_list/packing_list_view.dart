import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/commands/delete_packing_list_entry.dart';
import 'package:holiday_planner/src/rust/models.dart';

import 'add_packing_list_entry.dart';
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
                  child: Text("Error: ${snapshot.error}"),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return PackingList(snapshot.requireData, onRemove: _removeItem);
            }),
        Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _addItem,
              child: const Icon(Icons.add),
            ))
      ],
    );
  }

  void _fetch() {
    _packingList.addStream(getPackingList().asStream());
  }

  _addItem() async {
    await showAdaptiveDialog(
        context: context, builder: (context) => const AddItemDialog());
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

  const PackingList(this.packingList, {super.key, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (packingList.isEmpty) {
      return const Center(
        child: Text("No Items"),
      );
    }
    return ListView.builder(
        itemCount: packingList.length,
        itemBuilder: (context, index) {
          return PackingListItem(
              entry: packingList[index],
              onDelete: () => onRemove(packingList[index]));
        });
  }
}

class PackingListItem extends StatelessWidget {
  final PackingListEntry entry;
  final Function() onDelete;

  const PackingListItem(
      {required this.entry, super.key, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: Text(entry.name),
        trailing:
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete)),
        subtitle: Wrap(direction: Axis.horizontal, children: [
          for (var condition in entry.conditions)
            ConditionTag(condition: condition)
        ]));
  }
}
