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
    final totalCount = packingList.entries.length + packingList.groups.fold<int>(0, (acc, g) => acc + g.entries.length);
    if (totalCount == 0) {
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
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressHeader(context),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                for (final group in packingList.groups)
                  _GroupSection(
                    group: group,
                    onToggle: (entry) => _toggle(entry),
                  ),
                if (packingList.entries.isNotEmpty) ...[
                  for (final e in packingList.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPackingItem(context, e),
                    )
                  ]
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    
    int packedUngrouped = packingList.entries.where((e) => e.isPacked).length;
    int totalUngrouped = packingList.entries.length;
    int packedInGroups = packingList.groups.fold(0, (acc, g) => acc + g.entries.where((e) => e.isPacked).length);
    int totalInGroups = packingList.groups.fold(0, (acc, g) => acc + g.entries.length);
    int packedCount = packedUngrouped + packedInGroups;
    int totalCount = totalUngrouped + totalInGroups;
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
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: packingListEntry.isPacked 
              ? colorScheme.primary.withOpacity(0.5)
              : colorScheme.outlineVariant,
          width: packingListEntry.isPacked ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _toggle(packingListEntry),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Checkbox(
                value: packingListEntry.isPacked,
                onChanged: (value) => _toggle(packingListEntry),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    if (packingListEntry.quantity != null) ...[
                      Text(
                        "${packingListEntry.quantity}",
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: packingListEntry.isPacked
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.primary,
                          decoration: packingListEntry.isPacked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
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
                          if (packingListEntry.packingListEntry.description?.isNotEmpty == true) ...[
                            const SizedBox(height: 2),
                            Text(
                              packingListEntry.packingListEntry.description!,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                decoration: packingListEntry.isPacked 
                                    ? TextDecoration.lineThrough 
                                    : null,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (packingListEntry.isPacked)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 18,
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

class _GroupSection extends StatefulWidget {
  final TripPackingListGroup group;
  final Function(TripPackingListEntry) onToggle;
  const _GroupSection({required this.group, required this.onToggle});

  @override
  State<_GroupSection> createState() => _GroupSectionState();
}

class _GroupSectionState extends State<_GroupSection> {
  bool _expanded = true;


  @override
  void initState() {
    super.initState();
    _expanded = widget.group.entries.any((e) => !e.isPacked);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final total = widget.group.entries.length;
    final packed = widget.group.entries.where((e)=>e.isPacked).length;
    final allPacked = total > 0 && packed == total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpansionTile(
          initiallyExpanded: _expanded,
          onExpansionChanged: (v) => setState(() => _expanded = v),
          shape: const Border(),
          childrenPadding: const EdgeInsets.all(0),
          title: Row(
            children: [
              Icon(allPacked ? Icons.check_circle : Icons.folder_outlined,
                  color: allPacked ? colorScheme.primary : null, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.group.name,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Text("$packed / $total",
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
          children: [
            const SizedBox(height: 2),
            for (final e in widget.group.entries) ...[
              Padding(
                padding:
                    const EdgeInsets.only(left: 8.0),
                child: _TripPackingItemContent(
                    entry: e, onToggle: () => widget.onToggle(e)),
              )
            ],
            const SizedBox(height: 2),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _TripPackingItemContent extends StatelessWidget {
  final TripPackingListEntry entry;
  final VoidCallback onToggle;
  const _TripPackingItemContent({required this.entry, required this.onToggle});
  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: entry.isPacked 
              ? colorScheme.primary.withOpacity(0.5)
              : colorScheme.outlineVariant,
          width: entry.isPacked ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Checkbox(
                value: entry.isPacked,
                onChanged: (value) => onToggle(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    if (entry.quantity != null) ...[
                      Text(
                        "${entry.quantity}",
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: entry.isPacked
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.primary,
                          decoration: entry.isPacked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.packingListEntry.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: entry.isPacked 
                                  ? TextDecoration.lineThrough 
                                  : null,
                              color: entry.isPacked 
                                  ? colorScheme.onSurfaceVariant 
                                  : null,
                            ),
                          ),
                          if (entry.packingListEntry.description?.isNotEmpty == true) ...[
                            const SizedBox(height: 2),
                            Text(
                              entry.packingListEntry.description!,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                decoration: entry.isPacked 
                                    ? TextDecoration.lineThrough 
                                    : null,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (entry.isPacked)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
