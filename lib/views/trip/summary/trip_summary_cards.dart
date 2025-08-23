import 'package:flutter/material.dart';
import 'package:holiday_planner/colors.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/date_format.dart';
import 'package:holiday_planner/views/trip/accommodations/trip_accommodations.dart';
import 'package:holiday_planner/views/trip/bookings/trip_bookings.dart';
import 'package:holiday_planner/views/trip/transits/trip_transits.dart';
import 'package:holiday_planner/views/trip/locations/trip_locations.dart';
import 'package:holiday_planner/views/trip/points_of_interest/trip_points_of_interest.dart';

import '../packing_list/trip_packing_list.dart';

class PackingListCard extends StatelessWidget {
  final TripOverviewModel trip;
  final Function() refresh;

  const PackingListCard({required this.trip, super.key, required this.refresh});

  @override
  Widget build(BuildContext context) {
    String subtitle;
    if (trip.totalPackingListItems.toInt() == 0) {
      subtitle = "Nothing to pack";
    }else if (trip.pendingPackingListItems.toInt() == 0) {
      subtitle = "All items packed";
    }else if (trip.pendingPackingListItems.toInt() == 1) {
      subtitle = "1 item left to pack";
    }else {
      subtitle = "${trip.pendingPackingListItems} items left to pack";
    }
    return SummaryCard(
        icon: Icons.checklist,
        label: "Packing List",
        subtitle: subtitle,
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

class PointsOfInterestsCard extends StatelessWidget {
  final TripOverviewModel trip;
  final Function() refresh;

  const PointsOfInterestsCard({super.key, required this.trip, required this.refresh});

  @override
  Widget build(BuildContext context) {
    final count = trip.pointsOfInterestCount.toInt();
    final subtitle = "$count saved";
    
    return SummaryCard(
        icon: Icons.explore, 
        label: "Points of Interest",
        subtitle: subtitle,
        color: POINTS_OF_INTERESTS_COLOR,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TripPointsOfInterest(tripId: trip.id)),
          );
          refresh();
        });
  }
}

class AccommodationsCard extends StatelessWidget {
  final TripOverviewModel trip;
  final Function() refresh;

  const AccommodationsCard({super.key, required this.trip, required this.refresh});

  @override
  Widget build(BuildContext context) {
    String? subtitle;
    if (trip.accommodationStatus != null) {
      final status = trip.accommodationStatus!;
      final statusText = status.statusType == AccommodationStatusType.checkIn ? "Check-in" : "Check-out";
      final formattedDate = formatDate(status.datetime);
      subtitle = "$statusText at ${status.accommodationName} on $formattedDate";
    }
    
    return SummaryCard(
        icon: Icons.hotel,
        label: "Accommodations",
        subtitle: subtitle,
        color: ACCOMMODATIONS_COLOR,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TripAccommodations(tripId: trip.id)),
          );
          refresh();
        });
  }
}

class BookingsCard extends StatelessWidget {
  final TripOverviewModel trip;
  final Function() refresh;

  const BookingsCard({super.key, required this.trip, required this.refresh});

  @override
  Widget build(BuildContext context) {
    final count = trip.bookingsCount.toInt();
    final subtitle = count == 1 ? "1 booking" : "$count bookings";
    
    return SummaryCard(
        icon: Icons.confirmation_num,
        label: "Bookings",
        subtitle: subtitle,
        color: BOOKINGS_COLOR,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TripBookings(tripId: trip.id)),
          );
          refresh();
        });
  }
}

class TransitCard extends StatelessWidget {
  final TripOverviewModel trip;
  final Function() refresh;

  const TransitCard({super.key, required this.trip, required this.refresh});

  @override
  Widget build(BuildContext context) {
    return SummaryCard(
        icon: _icon,
        label: "Transits",
        subtitleChild: _subtitle,
        color: TRANSITS_COLOR,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TripTransits(tripId: trip.id)),
          );
          refresh();
        });
  }

  IconData get _icon {
    if (trip.nextTransit == null) {
      return Icons.directions_transit;
    }
    return trip.nextTransit!.maybeMap(
      orElse: () => Icons.directions_transit,
      departingTrain: (_) => Icons.train,
      arrivingTrain: (_) => Icons.train,
      departingFlight: (_) => Icons.flight,
      arrivingFlight: (_) => Icons.flight,
    );
  }

  Widget? get _subtitle {
    if (trip.nextTransit == null) {
      return null;
    }
    return trip.nextTransit!.mapOrNull(
        upcomingTransits: (transits) => Text("${transits.field0} upcoming"),
        departingTrain: (train) {
          return Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: "Departing at "),
                TextSpan(text: formatTime(train.field0.time), style: const TextStyle(fontWeight: FontWeight.w500)),
                const TextSpan(text: " from "),
                TextSpan(text: train.field0.station, style: const TextStyle(fontWeight: FontWeight.w500)),
                const TextSpan(text: " - Platform "),
                TextSpan(text: train.field0.platform, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
        arrivingTrain: (train) {
          return Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: "Arriving at "),
                TextSpan(text: formatTime(train.field0.time), style: const TextStyle(fontWeight: FontWeight.w500)),
                const TextSpan(text: " in "),
                TextSpan(text: train.field0.station, style: const TextStyle(fontWeight: FontWeight.w500)),
                const TextSpan(text: " - Platform "),
                TextSpan(text: train.field0.platform, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          );
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
  final TripOverviewModel trip;
  final Function() refresh;

  const LocationsCard({super.key, required this.trip, required this.refresh});

  @override
  Widget build(BuildContext context) {
    String? subtitle;
    if (trip.locationsList.isNotEmpty) {
      final locations = trip.locationsList.map((location) => "${location.city}, ${location.country}").join(" • ");
      subtitle = locations;
    }
    
    return SummaryCard(
        icon: Icons.location_on,
        label: "Locations",
        subtitle: subtitle,
        color: LOCATIONS_COLOR,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TripLocations(tripId: trip.id)),
          );
          refresh();
        });
  }
}

class SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? subtitleChild;
  final MaterialColor? color;
  final Function()? onTap;

  const SummaryCard(
      {super.key, required this.icon, required this.label, this.color, this.onTap, this.subtitle, this.subtitleChild});

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
                      if (subtitleChild != null) ...[
                        const SizedBox(height: 4),
                        subtitleChild!,
                      ]
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
