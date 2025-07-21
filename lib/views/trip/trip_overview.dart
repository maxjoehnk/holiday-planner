import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/date_format.dart';

import 'create_trip.dart';
import 'trip_view.dart';

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
                          MaterialPageRoute(builder: (context) => const CreateTripView()),
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

class TripList extends StatelessWidget {
  final List<TripListModel> trips;

  const TripList(
    this.trips, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.luggage_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              "No trips found",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              "Start planning your next adventure!",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView.separated(
        itemCount: trips.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          var trip = trips[i];
          return TripOverviewItem(
            trip: trip,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TripView(tripId: trip.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class TripOverviewItem extends StatelessWidget {
  final TripListModel trip;
  final Function() onTap;

  const TripOverviewItem({required this.trip, super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    var colorScheme = Theme.of(context).colorScheme;
    var start = formatDate(trip.startDate);
    var end = formatDate(trip.endDate);
    
    final duration = trip.endDate.difference(trip.startDate).inDays + 1;
    
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 160,
          child: Stack(
            children: [
              if (trip.headerImage != null)
                Positioned.fill(
                  child: Image.memory(
                    trip.headerImage!,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.secondaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.luggage,
                      size: 48,
                      color: colorScheme.onPrimaryContainer.withOpacity(0.6),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        trip.name,
                        style: textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              duration == 1 
                                ? start 
                                : "$start - $end",
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              duration == 1 
                                ? "1 day" 
                                : "$duration days",
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
