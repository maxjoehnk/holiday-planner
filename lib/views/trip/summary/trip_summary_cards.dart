import 'package:flutter/material.dart';
import 'package:holiday_planner/colors.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/views/trip/accommodations/trip_accommodations.dart';
import 'package:holiday_planner/views/trip/locations/trip_locations.dart';
import 'package:uuid/uuid.dart';

import '../packing_list/trip_packing_list.dart';

class PackingListCard extends StatelessWidget {
  final TripOverviewModel trip;
  final Function() refresh;

  const PackingListCard({required this.trip, super.key, required this.refresh});

  @override
  Widget build(BuildContext context) {
    return SummaryCard(
        icon: Icons.checklist,
        label: "Packing List",
        subtitle: "${trip.packedPackingListItems}/${trip.totalPackingListItems} packed",
        color: PACKING_LIST_COLOR,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TripPackingListView(tripId: trip.id)),
          );
          refresh();
        });
  }
}

class TransitsCard extends StatelessWidget {
  const TransitsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SummaryCard(icon: Icons.directions_transit, label: "Transits", color: TRANSITS_COLOR);
  }
}

class PointsOfInterestsCard extends StatelessWidget {
  const PointsOfInterestsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SummaryCard(
        icon: Icons.explore, label: "Points of Interest", color: POINTS_OF_INTERESTS_COLOR);
  }
}

class AccommodationsCard extends StatelessWidget {
  final UuidValue tripId;
  final Function() refresh;

  const AccommodationsCard({super.key, required this.tripId, required this.refresh});

  @override
  Widget build(BuildContext context) {
    return SummaryCard(
        icon: Icons.hotel,
        label: "Accommodations",
        color: ACCOMMODATIONS_COLOR,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TripAccommodations(tripId: tripId)),
          );
          refresh();
        });
  }
}

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SummaryCard(icon: Icons.wb_sunny, label: "Weather", color: WEATHER_COLOR);
  }
}

class LocationsCard extends StatelessWidget {
  final UuidValue tripId;
  final Function() refresh;

  const LocationsCard({super.key, required this.tripId, required this.refresh});

  @override
  Widget build(BuildContext context) {
    return SummaryCard(
        icon: Icons.location_on,
        label: "Locations",
        color: LOCATIONS_COLOR,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TripLocations(tripId: tripId)),
          );
          refresh();
        });
  }
}

class SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final MaterialColor? color;
  final Function()? onTap;

  const SummaryCard(
      {super.key, required this.icon, required this.label, this.color, this.onTap, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color?.shade300, child: Icon(icon)),
      title: Text(label),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: onTap,
    );
    // Card style for when the summary also shows transit information or forecasts
    return Card(
        clipBehavior: Clip.antiAlias,
        color: color,
        child: InkWell(
          onTap: onTap,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: Colors.black87),
                Text(label),
              ]),
        ));
  }
}
