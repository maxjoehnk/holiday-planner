import 'package:flutter/material.dart';
import 'package:holiday_planner/services/data_change_bus.dart';
import 'package:holiday_planner/services/refreshable_data.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/views/create_trip/create_trip.dart';
import 'package:holiday_planner/l10n/app_localizations.dart';

import 'trip_list.dart';

enum TripFilter { upcoming, past }

class TripOverview extends StatefulWidget {
  const TripOverview({super.key});

  @override
  State<TripOverview> createState() => _TripOverviewState();
}

class _TripOverviewState extends State<TripOverview> {
  TripFilter _selectedFilter = TripFilter.upcoming;
  late final _trips = RefreshableData<List<TripListModel>>(
    fetch: () => switch (_selectedFilter) {
      TripFilter.upcoming => getUpcomingTrips(),
      TripFilter.past => getPastTrips(),
    },
    refreshOn: [DataChangeBus.instance.onTripsChanged()],
  );

  @override
  void dispose() {
    _trips.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SegmentedButton<TripFilter>(
            segments: [
              ButtonSegment<TripFilter>(
                value: TripFilter.upcoming,
                label: Text(AppLocalizations.of(context)!.tripFilterUpcoming),
                icon: const Icon(Icons.upcoming),
              ),
              ButtonSegment<TripFilter>(
                value: TripFilter.past,
                label: Text(AppLocalizations.of(context)!.tripFilterPast),
                icon: const Icon(Icons.history),
              ),
            ],
            selected: {_selectedFilter},
            onSelectionChanged: (Set<TripFilter> newSelection) {
              setState(() {
                _selectedFilter = newSelection.first;
                _trips.refresh();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: _trips.stream,
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
                        AppLocalizations.of(context)!.errorWithMessage(snapshot.error.toString()),
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
                      label: Text(AppLocalizations.of(context)!.newTrip),
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
}
