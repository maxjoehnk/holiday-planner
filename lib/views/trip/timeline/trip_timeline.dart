import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:uuid/uuid.dart';

class TripTimeline extends StatelessWidget {
  final UuidValue tripId;

  const TripTimeline({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const SizedBox(height: 16),
          TimelineEntry(
            startTime: DateTime(2024, 9, 13, 13, 15),
            start: true,
            child: _buildTimelineCard(
              context,
              icon: Icons.flight,
              title: "Hamburg (HAM) to Manchester (MAN)",
              subtitle: "Eurowings · EW7768",
              color: Colors.blue,
            ),
          ),
          TimelineEntry(
            startTime: DateTime(2024, 9, 13, 14, 30),
            child: _buildTimelineCard(
              context,
              icon: Icons.car_rental,
              title: "Car Pickup",
              subtitle: "Arnold Clark",
              color: Colors.orange,
            ),
          ),
          TimelineEntry(
            startTime: DateTime(2024, 9, 13, 16, 00),
            child: _buildTimelineCard(
              context,
              icon: Icons.home,
              title: "Check-In",
              subtitle: "67 Park Street, Manchester",
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _buildTimelineCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
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

class TimelineEntry extends StatelessWidget {
  final bool start;
  final bool end;
  final Widget child;
  final DateTime startTime;
  final DateTime? endTime;

  const TimelineEntry(
      {super.key, this.start = false, this.end = false, required this.child, required this.startTime, this.endTime});

  @override
  Widget build(BuildContext context) {
    return TimelineTile(
      node: TimelineNode(
        startConnector: start ? const DashedLineConnector() : const SolidLineConnector(),
        endConnector: end ? const DashedLineConnector() : const SolidLineConnector(),
        indicator: const OutlinedDotIndicator(),
      ),
      nodePosition: 0.25,
      contents: child,
      oppositeContents: ListTile(
        title: Text(DateFormat.Hm().format(startTime)),
        subtitle: Text(DateFormat.yMEd().format(startTime)),
      ),
    );
  }
}
