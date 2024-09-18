import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:intl/intl.dart';

import 'create_trip.dart';
import 'trip_view.dart';

class TripOverview extends StatefulWidget {
  const TripOverview({super.key});

  @override
  State<TripOverview> createState() => _TripOverviewState();
}

class _TripOverviewState extends State<TripOverview> {
  late StreamController<List<Trip>> _trips;
  late Stream<List<Trip>>? _trips$;

  @override
  void initState() {
    super.initState();
    _trips = StreamController();
    _trips$ = _trips.stream;
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
        stream: _trips$,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: [
              TripList(snapshot.requireData),
              Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CreateTripView()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("New Trip"),
                  ))
            ],
          );
        });
  }

  _fetch() {
    _trips.addStream(getTrips().asStream());
  }
}

class TripList extends StatelessWidget {
  final List<Trip> trips;

  const TripList(
    this.trips, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return const Center(
        child: Text("No Trips"),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ListView.builder(
        itemCount: trips.length,
        itemBuilder: (context, i) {
          var trip = trips[i];
          return TripOverviewItem(
              trip: trip,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TripView(trip: trip),
                  ),
                );
              });
        },
      ),
    );
  }
}

class TripOverviewItem extends StatelessWidget {
  final Trip trip;
  final Function() onTap;

  const TripOverviewItem({required this.trip, super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    var start = DateFormat.yMMMMd().format(trip.startDate);
    var end = DateFormat.yMMMMd().format(trip.endDate);
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 128,
          child: Stack(
            children: [
              if (trip.headerImage != null)
                Image.memory(trip.headerImage!,
                    fit: BoxFit.cover, height: 128, width: double.infinity),
              Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.5)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trip.name,
                            style: textTheme.titleMedium!
                                .copyWith(color: Colors.white)),
                        Text("$start - $end",
                            style: textTheme.titleSmall!
                                .copyWith(color: Colors.white70))
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
