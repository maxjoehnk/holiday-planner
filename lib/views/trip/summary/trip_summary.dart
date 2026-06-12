import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';

import 'trip_summary_cards.dart';

class TripSummary extends StatelessWidget {
  final TripOverviewModel trip;

  const TripSummary(this.trip, {super.key});

  @override
  Widget build(BuildContext context) {
    var summaryCards = <Widget>[
      PackingListCard(trip: trip),
      TransitCard(trip: trip),
      PointsOfInterestsCard(trip: trip),
      AccommodationsCard(trip: trip),
      LocationsCard(trip: trip),
      BookingsCard(trip: trip),
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
