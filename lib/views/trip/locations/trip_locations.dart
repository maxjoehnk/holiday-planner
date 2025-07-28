import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:holiday_planner/src/rust/api.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/src/rust/commands/add_trip_location.dart';
import 'package:holiday_planner/date_format.dart';
import 'package:holiday_planner/src/rust/models/tidal_information.dart';
import 'package:holiday_planner/widgets/location_search.dart';
import 'package:holiday_planner/views/trip/locations/forecast_detail_view.dart';
import 'package:holiday_planner/views/trip/locations/tidal_detail_view.dart';
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
                return LocationCard(
                  location: location,
                  onUpdate: _fetch,
                );
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

class LocationCard extends StatefulWidget {
  final TripLocationListModel location;
  final VoidCallback? onUpdate;

  const LocationCard({required this.location, this.onUpdate, super.key});

  @override
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard> {
  bool _isUpdatingCoastal = false;

  Future<void> _updateCoastalFlag(bool isCoastal) async {
    setState(() {
      _isUpdatingCoastal = true;
    });

    try {
      await updateCoastalFlag(locationId: widget.location.id, isCoastal: isCoastal);
      
      // If enabling coastal flag, trigger background job to fetch tidal data
      if (isCoastal) {
        try {
          await runBackgroundJobs();
        } catch (e) {
          // Background job failed, but coastal flag was updated successfully
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Coastal flag updated, but tidal data sync failed: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
      
      widget.onUpdate?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update coastal flag: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingCoastal = false;
        });
      }
    }
  }

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
                    widget.location.isCoastal ? Icons.waves : Icons.location_on,
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
                        widget.location.city,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.location.country,
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
            const SizedBox(height: 16),
            // Coastal flag toggle
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.waves,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Coastal Location",
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (_isUpdatingCoastal)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Switch(
                      value: widget.location.isCoastal,
                      onChanged: _updateCoastalFlag,
                    ),
                ],
              ),
            ),
            // Tidal information display
            if (widget.location.isCoastal && widget.location.tidalInformation.isNotEmpty) ...[
              const SizedBox(height: 12),
              TidalInformationWidget(
                tidalInformation: widget.location.tidalInformation,
                location: widget.location,
              ),
            ],
            if (widget.location.forecast != null) ...[
              const SizedBox(height: 16),
              LocationDailyForecast(
                forecast: widget.location.forecast!,
                location: widget.location,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TidalInformationWidget extends StatelessWidget {
  final List<TidalInformation> tidalInformation;
  final TripLocationListModel location;

  const TidalInformationWidget({
    required this.tidalInformation,
    required this.location,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    if (tidalInformation.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 16,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Text(
              "No tidal data available",
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TidalDetailView(location: location),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.waves,
                size: 16,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                "Tidal Information",
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                "Updated: ${location.tidalInformationLastUpdated != null ? DateFormat('MMM d, HH:mm').format(location.tidalInformationLastUpdated!.toLocal()) : 'Never'}",
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                ),
              ),
            ],
          ),
          if (tidalInformation.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...(tidalInformation.take(4).map((tideInfo) {
              final DateTime tideTime = tideInfo.date;
              final String tideType = tideInfo.tide == TideType.high ? 'High' : 'Low';
              final double height = tideInfo.height;
              
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      tideType == 'High' ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 14,
                      color: tideType == 'High' ? Colors.blue : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$tideType Tide",
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${height.toStringAsFixed(1)}m",
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM d, HH:mm').format(tideTime.toLocal()),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }).toList()),
          ],
        ],
      ),
    ));
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
