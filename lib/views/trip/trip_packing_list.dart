import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';

class TripPackingListView extends StatefulWidget {
  final Trip trip;

  const TripPackingListView({super.key, required this.trip});

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
        backgroundColor: Colors.green.shade300,
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
              trip: widget.trip,
              packingList: snapshot.requireData,
              onToggleItem: () => _fetch());
        },
      ),
    );
  }

  _fetch() {
    _packingList
        .addStream(getTripPackingList(tripId: widget.trip.id).asStream());
  }
}

class PackingList extends StatelessWidget {
  final Trip trip;
  final TripPackingListModel packingList;
  final Function() onToggleItem;

  const PackingList(
      {super.key,
      required this.packingList,
      required this.trip,
      required this.onToggleItem});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: packingList.visible.length,
      itemBuilder: (context, index) {
        var packingListEntry = packingList.visible[index];
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
          tripId: trip.id, entryId: entry.packingListEntry.id);
    } else {
      await markAsPacked(
          tripId: trip.id, entryId: entry.packingListEntry.id);
    }
    onToggleItem();
  }
}
