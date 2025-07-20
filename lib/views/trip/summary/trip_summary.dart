import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';

import 'trip_summary_cards.dart';

class TripSummary extends StatelessWidget {
  final TripOverviewModel trip;
  final Function() refresh;

  const TripSummary(this.trip, {super.key, required this.refresh});

  @override
  Widget build(BuildContext context) {
    var summaryCards = [
      PackingListCard(trip: trip, refresh: refresh),
      const TransitsCard(),
      const PointsOfInterestsCard(),
      AccommodationsCard(tripId: trip.id, refresh: refresh),
      LocationsCard(tripId: trip.id, refresh: refresh),
      const TicketsCard(),
    ];

    return SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            return summaryCards[index];
          },
          childCount: summaryCards.length,
        ));
  }
}
