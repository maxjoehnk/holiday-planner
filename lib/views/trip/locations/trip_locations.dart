import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/src/rust/commands/add_trip_location.dart';
import 'package:holiday_planner/date_format.dart';
import 'package:holiday_planner/widgets/location_search.dart';
import 'package:holiday_planner/views/trip/locations/forecast_detail_view.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:uuid/uuid.dart';

const Duration debounceDuration = Duration(milliseconds: 500);

class TripLocations extends StatefulWidget {
  final UuidValue tripId;

  const TripLocations({super.key, required this.tripId});

  @override
  State<TripLocations> createState() => _TripLocationsState();
}

class _TripLocationsState extends State<TripLocations> {
  late StreamController<List<TripLocationListModel>> _locations;
  late Stream<List<TripLocationListModel>>? _locations$;

  @override
  void initState() {
    super.initState();
    _locations = StreamController();
    _locations$ = _locations.stream;
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Locations"),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: _locations$,
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

          var locations = snapshot.requireData;
          if (locations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No locations",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Add destinations to see weather forecasts and plan activities",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.separated(
              itemCount: locations.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                var location = locations[index];
                return LocationCard(location: location);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "locations_fab",
        onPressed: () => _addLocation(context),
        icon: const Icon(Icons.add),
        label: const Text("Add Location"),
      ),
    );
  }

  void _addLocation(BuildContext context) async {
    LocationEntry? location = await showDialog(
        context: context, builder: (context) => const AddLocation());
    if (location == null) {
      return;
    }
    await addTripLocation(
        command: AddTripLocation(tripId: widget.tripId, location: location));

    _fetch();
  }

  _fetch() {
    _locations.addStream(getTripLocations(tripId: widget.tripId).asStream());
  }
}

class LocationCard extends StatelessWidget {
  final TripLocationListModel location;

  const LocationCard({required this.location, super.key});

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_on,
                    size: 24,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.city,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location.country,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (location.forecast != null) ...[
              const SizedBox(height: 16),
              LocationDailyForecast(
                forecast: location.forecast!,
                location: location,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Map<WeatherCondition, IconData> weatherIcons = {
  WeatherCondition.sunny: MdiIcons.weatherSunny,
  WeatherCondition.clouds: MdiIcons.weatherCloudy,
  WeatherCondition.rain: MdiIcons.weatherRainy,
  WeatherCondition.snow: MdiIcons.weatherSnowy,
  WeatherCondition.thunderstorm: MdiIcons.weatherLightning,
};

Map<WeatherCondition, Color> weatherColors = {
  WeatherCondition.sunny: Colors.yellowAccent.shade700,
  WeatherCondition.clouds: Colors.grey.shade600,
  WeatherCondition.rain: Colors.blue.shade700,
  WeatherCondition.snow: Colors.black,
  WeatherCondition.thunderstorm: Colors.grey.shade800
};

class LocationDailyForecast extends StatelessWidget {
  final WeatherForecast forecast;
  final TripLocationListModel location;

  const LocationDailyForecast({super.key, required this.forecast, required this.location});

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.wb_sunny_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Weather Forecast",
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ForecastDetailView(location: location),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Details",
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: forecast.dailyForecast.map((dayForecast) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatDate(dayForecast.day, format: DateFormat.Md()),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          weatherIcons[dayForecast.condition] ?? Icons.wb_sunny,
                          size: 32,
                          color: weatherColors[dayForecast.condition] ?? colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${dayForecast.maxTemperature.toStringAsFixed(0)}°",
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "${dayForecast.minTemperature.toStringAsFixed(0)}°",
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}


class AddLocation extends StatefulWidget {
  const AddLocation({super.key});

  @override
  State<AddLocation> createState() => _AddLocationState();
}

class _AddLocationState extends State<AddLocation> {
  LocationEntry? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    var colorScheme = Theme.of(context).colorScheme;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.add_location,
                    size: 20,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "Add Location",
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _selectedLocation == null
                      ? null
                      : () => Navigator.of(context).pop(_selectedLocation),
                  child: const Text("Add"),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Flexible(
              child: LocationSearch(
                onSelect: (entry) => setState(() => _selectedLocation = entry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
