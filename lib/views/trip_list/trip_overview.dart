import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/views/create_trip/create_trip.dart';

import 'trip_list.dart';

enum TripFilter { upcoming, past }

class TripOverview extends StatefulWidget {
  const TripOverview({super.key});

  @override
  State<TripOverview> createState() => _TripOverviewState();
}

class _TripOverviewState extends State<TripOverview> {
  late StreamController<List<TripListModel>> _trips;
  late Stream<List<TripListModel>>? _trips$;
  TripFilter _selectedFilter = TripFilter.upcoming;

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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SegmentedButton<TripFilter>(
            segments: const [
              ButtonSegment<TripFilter>(
                value: TripFilter.upcoming,
                label: Text('Upcoming'),
                icon: Icon(Icons.upcoming),
              ),
              ButtonSegment<TripFilter>(
                value: TripFilter.past,
                label: Text('Past'),
                icon: Icon(Icons.history),
              ),
            ],
            selected: {_selectedFilter},
            onSelectionChanged: (Set<TripFilter> newSelection) {
              setState(() {
                _selectedFilter = newSelection.first;
                _fetch();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: _trips$,
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
              return Stack(
                children: [
                  TripList(snapshot.requireData),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.extended(
                      heroTag: "trip_overview_fab",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CreateTripView()),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("New Trip"),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  _fetch() {
    switch (_selectedFilter) {
      case TripFilter.upcoming:
        _trips.addStream(getUpcomingTrips().asStream());
        break;
      case TripFilter.past:
        _trips.addStream(getPastTrips().asStream());
        break;
    }
  }
}
