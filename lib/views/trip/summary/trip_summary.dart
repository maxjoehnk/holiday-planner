import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';

import 'trip_summary_cards.dart';

class TripSummary extends StatelessWidget {
  final TripOverviewModel trip;
  final Function() refresh;

  const TripSummary(this.trip, {super.key, required this.refresh});

  @override
  Widget build(BuildContext context) {
    var summaryCards = <Widget>[
      PackingListCard(trip: trip, refresh: refresh),
    ];

    // Add WeatherTidalCard if single location weather/tidal data is available
    if (trip.singleLocationWeatherTidal != null) {
      summaryCards.add(
        WeatherTidalCard(
          location: trip.singleLocationWeatherTidal!,
          refresh: refresh,
        ),
      );
    }

    summaryCards.addAll([
      TransitCard(trip: trip, refresh: refresh),
      PointsOfInterestsCard(trip: trip, refresh: refresh),
      AccommodationsCard(trip: trip, refresh: refresh),
      LocationsCard(trip: trip, refresh: refresh),
      BookingsCard(trip: trip, refresh: refresh),
    ]);

    return SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            return summaryCards[index];
          },
          childCount: summaryCards.length,
        ));
  }
}
