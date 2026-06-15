import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holiday_planner/date_format.dart';
import 'package:holiday_planner/l10n/app_localizations.dart';
import 'package:holiday_planner/services/data_change_bus.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/views/packing_list/pollen_selector.dart';
import 'package:intl/intl.dart';

class PollenDetailView extends StatefulWidget {
  final TripLocationListModel location;

  const PollenDetailView({super.key, required this.location});

  @override
  State<PollenDetailView> createState() => _PollenDetailViewState();
}

class _PollenDetailViewState extends State<PollenDetailView> {
  late TripLocationListModel location;
  StreamSubscription<void>? _changeSub;

  @override
  void initState() {
    super.initState();
    location = widget.location;
    _changeSub = DataChangeBus.instance
        .onLocationDataChanged(widget.location.id)
        .listen((_) => _refresh());
  }

  @override
  void dispose() {
    _changeSub?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final updated = await getLocationDetails(locationId: widget.location.id);
      if (mounted) {
        setState(() {
          location = updated;
        });
      }
    } catch (_) {
      // ignore — keep showing the existing forecast
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pollen = location.pollenForecast;
    final title =
        '${location.city} ${AppLocalizations.of(context)!.pollenSelectorTitle}';

    if (pollen == null || pollen.daily.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(title), centerTitle: true),
        body: Center(
          child: Text(AppLocalizations.of(context)!.pollenNoData),
        ),
      );
    }

    final grouped = <DateTime, List<DailyPollenForecast>>{};
    for (final entry in pollen.daily) {
      final key = DateTime.utc(entry.day.year, entry.day.month, entry.day.day);
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    final days = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colorScheme, textTheme),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.pollenDailyTitle,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: days.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final day = days[index];
                final entries = grouped[day]!
                  ..sort((a, b) =>
                      a.pollenType.index.compareTo(b.pollenType.index));
                return _PollenDayCard(day: day, entries: entries);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_florist,
                size: 24,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.city,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location.country,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PollenDayCard extends StatelessWidget {
  final DateTime day;
  final List<DailyPollenForecast> entries;

  const _PollenDayCard({required this.day, required this.entries});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatDate(day, format: DateFormat.yMMMMEEEEd()),
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const Divider(height: 16),
            _PollenTypeRow(entry: entries[i]),
          ],
        ],
      ),
    );
  }
}

class _PollenTypeRow extends StatelessWidget {
  final DailyPollenForecast entry;

  const _PollenTypeRow({required this.entry});

  Color _color(int value) {
    if (value <= 0) return Colors.grey;
    if (value <= 2) return Colors.green.shade600;
    if (value <= 3) return Colors.amber.shade700;
    if (value <= 4) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final color = _color(entry.indexValue);

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(iconForPollenType(entry.pollenType), size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                labelForPollenType(entry.pollenType, context),
                style: textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (entry.category != null)
                Text(
                  entry.category!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        _IndexBar(value: entry.indexValue, color: color),
        const SizedBox(width: 12),
        Text(
          '${entry.indexValue}/5',
          style: textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _IndexBar extends StatelessWidget {
  final int value;
  final Color color;

  const _IndexBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 80,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: (value.clamp(0, 5)) / 5.0,
          minHeight: 6,
          backgroundColor: colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}
