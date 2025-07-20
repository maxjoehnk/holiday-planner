import 'package:flutter/material.dart';
import 'package:holiday_planner/colors.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/views/trip/accommodations/trip_accommodations.dart';
import 'package:holiday_planner/views/trip/locations/trip_locations.dart';
import 'package:holiday_planner/views/trip/points_of_interest/trip_points_of_interest.dart';
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
  final UuidValue tripId;
  final Function() refresh;

  const PointsOfInterestsCard({super.key, required this.tripId, required this.refresh});

  @override
  Widget build(BuildContext context) {
    return SummaryCard(
        icon: Icons.explore, 
        label: "Points of Interest", 
        color: POINTS_OF_INTERESTS_COLOR,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TripPointsOfInterest(tripId: tripId)),
          );
          refresh();
        });
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


class BookingsCard extends StatelessWidget {
  const BookingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SummaryCard(icon: Icons.confirmation_num, label: "Bookings", color: TICKETS_COLOR);
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
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Card(
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
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color?.shade100 ?? colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: color?.shade700 ?? colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
