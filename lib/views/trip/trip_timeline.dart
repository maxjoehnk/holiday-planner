import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';
import 'package:timelines_plus/timelines_plus.dart';

class TripTimeline extends StatelessWidget {
  final Trip trip;

  const TripTimeline({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return SliverList(
        delegate: SliverChildListDelegate([
      TimelineEntry(
          startTime: DateTime(2024, 9, 13, 13, 15),
          start: true,
          child: const Card(
              child: Padding(
            padding: EdgeInsets.all(0.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                leading: Icon(Icons.flight),
                title: Text("Hamburg (HAM) to Manchester (MAN)"),
                subtitle: Text("Eurowings · EW7768"),
              )
            ]),
          ))),
      TimelineEntry(
          startTime: DateTime(2024, 9, 13, 14, 30),
          child: const Card(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: Icon(Icons.car_rental),
              title: Text("Car Pickup"),
              subtitle: Text("Arnorld Clark"),
            )
          ]))),
      TimelineEntry(
          startTime: DateTime(2024, 9, 13, 16, 00),
          child: Card(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: Brand(
                Brands.airbnb,
                size: 24,
              ),
              title: const Text("Check-In"),
              subtitle: const Text("67 Park Street, Manchester"),
            )
          ])))
    ]));
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
