import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holiday_planner/colors.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:uuid/uuid.dart';

class TripPackingListView extends StatefulWidget {
  final UuidValue tripId;

  const TripPackingListView({super.key, required this.tripId});

  @override
  State<TripPackingListView> createState() => _TripPackingListViewState();
}

class _TripPackingListViewState extends State<TripPackingListView> {
  late StreamController<TripPackingListModel> _packingList;
  late Stream<TripPackingListModel>? _packingList$;

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: PACKING_LIST_COLOR,
        title: const Text("Packing List"),
      ),
      body: StreamBuilder(
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
          return PackingList(
              tripId: widget.tripId,
              packingList: snapshot.requireData,
              onToggleItem: () => _fetch());
        },
      ),
    );
  }

  _fetch() {
    _packingList
        .addStream(getTripPackingList(tripId: widget.tripId).asStream());
  }
}

class PackingList extends StatelessWidget {
  final UuidValue tripId;
  final TripPackingListModel packingList;
  final Function() onToggleItem;

  const PackingList(
      {super.key,
      required this.packingList,
      required this.tripId,
      required this.onToggleItem});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: packingList.entries.length,
      itemBuilder: (context, index) {
        var packingListEntry = packingList.entries[index];
        return ListTile(
          leading: Checkbox(
              value: packingListEntry.isPacked,
              onChanged: (value) => _toggle(packingListEntry)),
          title: Text(packingListEntry.packingListEntry.name),
          subtitle: packingListEntry.quantity == null
              ? null
              : Text("${packingListEntry.quantity} Time(s)"),
          onTap: () => _toggle(packingListEntry),
        );
      },
    );
  }

  _toggle(TripPackingListEntry entry) async {
    if (entry.isPacked) {
      await markAsUnpacked(
          tripId: tripId, entryId: entry.packingListEntry.id);
    } else {
      await markAsPacked(
          tripId: tripId, entryId: entry.packingListEntry.id);
    }
    onToggleItem();
  }
}
