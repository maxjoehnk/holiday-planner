import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/views/trip/trip_locations.dart';

import 'trip_packing_list.dart';

class PackingListCard extends StatelessWidget {
  static Color color = Colors.green.shade300;

  final Trip trip;

  const PackingListCard({required this.trip, super.key});

  @override
  Widget build(BuildContext context) {
    return SummaryCard(
        icon: Icons.checklist,
        label: "Packing List",
        color: color,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => TripPackingListView(trip: trip)),
          );
        });
  }
}

class TransitsCard extends StatelessWidget {
  static Color color = Colors.blue.shade300;

  const TransitsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SummaryCard(
        icon: Icons.directions_transit, label: "Transits", color: color);
  }
}

class PointsOfInterestsCard extends StatelessWidget {
  static Color color = Colors.orange.shade300;

  const PointsOfInterestsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SummaryCard(
        icon: Icons.explore, label: "Points of Interest", color: color);
  }
}

class AccommodationsCard extends StatelessWidget {
  static Color color = Colors.purple.shade300;

  const AccommodationsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SummaryCard(
        icon: Icons.hotel, label: "Accommodations", color: color);
  }
}

class WeatherCard extends StatelessWidget {
  static Color color = Colors.yellow.shade300;

  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SummaryCard(icon: Icons.wb_sunny, label: "Weather", color: color);
  }
}

class LocationsCard extends StatelessWidget {
  static Color color = Colors.red.shade300;

  final Trip trip;

  const LocationsCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return SummaryCard(
        icon: Icons.location_on,
        label: "Locations",
        color: color,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TripLocations(trip: trip)),
          );
        });
  }
}

class SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? color;
  final Function()? onTap;

  const SummaryCard(
      {super.key,
      required this.icon,
      required this.label,
      this.color,
      this.onTap,
      this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color, child: Icon(icon)),
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
