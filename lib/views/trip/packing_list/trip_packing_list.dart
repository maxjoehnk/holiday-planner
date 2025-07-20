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
        title: const Text("Packing List"),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder(
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
    if (packingList.entries.isEmpty) {
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
              "Items will appear here based on your trip conditions",
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressHeader(context),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: packingList.entries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                var packingListEntry = packingList.entries[index];
                return _buildPackingItem(context, packingListEntry);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    
    int packedCount = packingList.entries.where((e) => e.isPacked).length;
    int totalCount = packingList.entries.length;
    double progress = totalCount > 0 ? packedCount / totalCount : 0.0;
    
    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.checklist,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  "Packing Progress",
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "$packedCount of $totalCount items packed",
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: colorScheme.onPrimaryContainer.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimaryContainer),
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackingItem(BuildContext context, TripPackingListEntry packingListEntry) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: packingListEntry.isPacked 
              ? colorScheme.primary.withOpacity(0.5)
              : colorScheme.outlineVariant,
          width: packingListEntry.isPacked ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _toggle(packingListEntry),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Checkbox(
                value: packingListEntry.isPacked,
                onChanged: (value) => _toggle(packingListEntry),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      packingListEntry.packingListEntry.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: packingListEntry.isPacked 
                            ? TextDecoration.lineThrough 
                            : null,
                        color: packingListEntry.isPacked 
                            ? colorScheme.onSurfaceVariant 
                            : null,
                      ),
                    ),
                    if (packingListEntry.quantity != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        "${packingListEntry.quantity} item(s)",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (packingListEntry.isPacked)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
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
