import 'package:flutter/material.dart';
import 'package:holiday_planner/colors.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/date_format.dart';
import 'package:holiday_planner/src/rust/models/tidal_information.dart';
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
        icon: Icons.directions_transit,
        label: "Transits",
        color: TRANSITS_COLOR,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TripTransits(tripId: trip.id)),
          );
          refresh();
        });
  }
}

class WeatherTidalCard extends StatelessWidget {
  final TripLocationListModel location;
  final Function() refresh;

  const WeatherTidalCard({super.key, required this.location, required this.refresh});

  @override
  Widget build(BuildContext context) {
    var todayCondition = location.forecast?.dailyForecast.firstOrNull?.condition;
    return SummaryCard(
      icon: _getWeatherIcon(),
      label: "${location.city}, ${location.country}",
      subtitle: _buildSubtitle(),
      color: todayCondition != null ? _getWeatherConditionColor(todayCondition) : WEATHER_COLOR,
    );
  }

  String _buildSubtitle() {
    List<String> subtitleParts = [];
    
    // Add weather information
    if (location.forecast?.dailyForecast.isNotEmpty == true) {
      final today = location.forecast!.dailyForecast.first;
      final tempRange = "${today.minTemperature.round()}° - ${today.maxTemperature.round()}°C";
      final condition = _getWeatherConditionText(today.condition);
      subtitleParts.add("$tempRange, $condition");
      
      if (today.precipitationProbability > 0.1) {
        subtitleParts.add("${(today.precipitationProbability * 100).round()}% rain");
      }
    } else {
      subtitleParts.add("No weather data");
    }
    
    // Add tidal information if available
    if (location.isCoastal && location.tidalInformation.isNotEmpty) {
      final nextTide = location.tidalInformation.first;
      final isHigh = nextTide.tide == TideType.high;
      final time = "${nextTide.date.hour.toString().padLeft(2, '0')}:${nextTide.date.minute.toString().padLeft(2, '0')}";
      subtitleParts.add("${isHigh ? 'High' : 'Low'} tide at $time");
    }
    
    return subtitleParts.join(" • ");
  }

  IconData _getWeatherIcon() {
    if (location.forecast?.dailyForecast.isNotEmpty == true) {
      return _getWeatherConditionIcon(location.forecast!.dailyForecast.first.condition);
    }
    return Icons.wb_sunny;
  }

  IconData _getWeatherConditionIcon(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return Icons.wb_sunny;
      case WeatherCondition.rain:
        return Icons.grain;
      case WeatherCondition.clouds:
        return Icons.cloud;
      case WeatherCondition.snow:
        return Icons.ac_unit;
      case WeatherCondition.thunderstorm:
        return Icons.thunderstorm;
    }
  }

  MaterialColor _getWeatherConditionColor(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return Colors.orange;
      case WeatherCondition.rain:
        return Colors.blue;
      case WeatherCondition.clouds:
        return Colors.grey;
      case WeatherCondition.snow:
        return Colors.lightBlue;
      case WeatherCondition.thunderstorm:
        return Colors.purple;
    }
  }

  String _getWeatherConditionText(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return "Sunny";
      case WeatherCondition.rain:
        return "Rain";
      case WeatherCondition.clouds:
        return "Cloudy";
      case WeatherCondition.snow:
        return "Snow";
      case WeatherCondition.thunderstorm:
        return "Thunderstorm";
    }
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
