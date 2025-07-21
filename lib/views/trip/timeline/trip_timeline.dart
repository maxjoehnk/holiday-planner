import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holiday_planner/colors.dart';
import 'package:holiday_planner/src/rust/api/timeline.dart';
import 'package:holiday_planner/src/rust/models/timeline.dart';
import 'package:holiday_planner/date_format.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:uuid/uuid.dart';

class TripTimeline extends StatefulWidget {
  final UuidValue tripId;

  const TripTimeline({super.key, required this.tripId});

  @override
  State<TripTimeline> createState() => _TripTimelineState();
}

class _TripTimelineState extends State<TripTimeline> {
  late StreamController<TimelineModel> _timeline;
  late Stream<TimelineModel>? _timeline$;

  @override
  void initState() {
    super.initState();
    _timeline = StreamController();
    _timeline$ = _timeline.stream;
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
    return StreamBuilder(
        stream: _timeline$,
        builder: (context, snapshot) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                for (var (i, item) in (snapshot.data?.future ?? []).indexed)
                  TimelineEntry(
                    startTime: item.date,
                    start: i == 0,
                    child: TimelineCard(itemDetails: item.details),
                  ),
                const SizedBox(height: 16),
              ]),
            ),
          );
        });
  }

  _fetch() {
    _timeline.addStream(getTripTimeline(tripId: widget.tripId).asStream());
  }
}

class TimelineEntry extends StatelessWidget {
  final bool start;
  final bool end;
  final Widget child;
  final DateTime startTime;
  final DateTime? endTime;

  const TimelineEntry(
      {super.key,
      this.start = false,
      this.end = false,
      required this.child,
      required this.startTime,
      this.endTime});

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
        title: Text(formatTime(startTime)),
        subtitle: Text(formatDate(startTime)),
      ),
    );
  }
}

class TimelineCard extends StatelessWidget {
  final TimelineItemDetails itemDetails;

  const TimelineCard({super.key, required this.itemDetails});

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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: color.shade700,
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
                  if (subtitle != null)
                    Text(
                      subtitle!,
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

  MaterialColor get color {
    return itemDetails.map(
      carRentalPickUp: (_) => CAR_RENTAL_COLOR,
      carRentalDropOff: (_) => CAR_RENTAL_COLOR,
      reservation: (_) => BOOKINGS_COLOR,
      checkIn: (_) => ACCOMMODATIONS_COLOR,
      checkOut: (_) => ACCOMMODATIONS_COLOR,
      flightTakeOff: (_) => TRANSITS_COLOR,
      flightLanding: (_) => TRANSITS_COLOR,
      trainOrigin: (_) => TRANSITS_COLOR,
      trainDestination: (_) => TRANSITS_COLOR,
    );
  }

  String get title {
    return itemDetails.map(
      carRentalPickUp: (_) => "Car Pickup",
      carRentalDropOff: (_) => "Car Drop off",
      reservation: (item) => item.title,
      checkIn: (_) => "Check-In",
      checkOut: (_) => "Check-Out",
      flightTakeOff: (flight) => flight.airport,
      flightLanding: (flight) => flight.airport,
      trainOrigin: (train) => train.station,
      trainDestination: (train) => train.station,
    );
  }

  String? get subtitle {
    return itemDetails.map(
      carRentalPickUp: (item) => item.provider,
      carRentalDropOff: (item) => item.provider,
      reservation: (item) => item.address,
      checkIn: (item) => item.address,
      checkOut: (item) => item.address,
      flightTakeOff: (item) => "${item.flightNumber} · ${item.seat ?? ""}",
      flightLanding: (item) => item.flightNumber,
      trainOrigin: (train) => "${train.station} · ${train.seat ?? ""}",
      trainDestination: (train) => train.station,
    );
  }

  IconData get icon {
    return itemDetails.map(
        carRentalPickUp: (_) => Icons.car_rental,
        carRentalDropOff: (_) => Icons.car_rental,
        reservation: (_) => Icons.restaurant,
        checkIn: (_) => Icons.home,
        checkOut: (_) => Icons.home,
        trainOrigin: (_) => Icons.train,
        trainDestination: (_) => Icons.train,
        flightTakeOff: (_) => Icons.flight_takeoff,
        flightLanding: (_) => Icons.flight_land);
  }
}
