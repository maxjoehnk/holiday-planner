import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holiday_planner/colors.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/src/rust/commands/add_trip_location.dart';
import 'package:holiday_planner/views/trip/section_theme.dart';
import 'package:holiday_planner/widgets/location_search.dart';
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
    return SectionTheme(
      color: LOCATIONS_COLOR,
      child: Scaffold(
          appBar: AppBar(
            title: const Text("Locations"),
          ),
          body: StreamBuilder(
            stream: _locations$,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text("Error: ${snapshot.error}"),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView.builder(
                itemCount: snapshot.requireData.length,
                itemBuilder: (context, index) {
                  var location = snapshot.requireData[index];
                  return LocationCard(
                    location: location,
                  );
                },
              );
            }
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addLocation(context),
            child: const Icon(Icons.add),
          )),
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
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(location.city),
                subtitle: Text(location.country),
              ),
              if (location.forecast != null)
                LocationDailyForecast(location.forecast!),
            ]),
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

class LocationDailyForecast extends StatefulWidget {
  final WeatherForecast forecast;

  const LocationDailyForecast(this.forecast, {super.key});

  @override
  State<LocationDailyForecast> createState() => _LocationDailyForecastState();
}

class _LocationDailyForecastState extends State<LocationDailyForecast> {
  DailyWeatherForecast? selectedDay;

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
              children: widget.forecast.dailyForecast
          .map((dayForecast) {
            return InkWell(
              onTap: () => setState(() => selectedDay = dayForecast),
              child: Container(
                decoration: BoxDecoration(
                  color: selectedDay == dayForecast ? Colors.black12 : null,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(DateFormat.Md().format(dayForecast.day)),
                      Icon(weatherIcons[dayForecast.condition], size: 48, color: weatherColors[dayForecast.condition]),
                      Text("${dayForecast.maxTemperature.toStringAsFixed(1)}°C", style: textTheme.titleMedium),
                      Text("${dayForecast.minTemperature.toStringAsFixed(1)}°C", style: textTheme.titleSmall),
                    ],
                  ),
                ),
              ),
            );
          }).toList()),
        ),
        if (selectedDay != null)
          LocationHourlyForecast(widget.forecast.hourlyForecast.where((f) => f.time.day == selectedDay!.day.day).toList())
      ],
    );
  }
}

class LocationHourlyForecast extends StatelessWidget {
  final List<HourlyWeatherForecast> forecast;

  const LocationHourlyForecast(this.forecast, {super.key});

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: forecast.map((hourForecast) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(DateFormat.Hm().format(hourForecast.time)),
              Icon(weatherIcons[hourForecast.condition], size: 48, color: weatherColors[hourForecast.condition]),
              Text("${hourForecast.temperature.toStringAsFixed(1)}°C", style: textTheme.titleMedium),
            ],
          ),
        );
      }).toList()),
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
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Add Location", style: textTheme.titleLarge),
            const SizedBox(height: 16),
            LocationSearch(
                onSelect: (entry) => setState(() => _selectedLocation = entry)),
            const SizedBox(height: 16),
            OverflowBar(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: _selectedLocation == null
                      ? null
                      : () => Navigator.of(context).pop(_selectedLocation),
                  child: const Text("Add"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
