import 'package:flutter/material.dart';
import 'package:holiday_planner/ffi.dart';
import 'package:holiday_planner/widgets/location_search.dart';

import 'trip_summary.dart';

const Duration debounceDuration = Duration(milliseconds: 500);

class TripLocations extends StatefulWidget {
  final Trip trip;

  const TripLocations({super.key, required this.trip});

  @override
  State<TripLocations> createState() => _TripLocationsState();
}

class _TripLocationsState extends State<TripLocations> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Locations"),
          backgroundColor: LocationsCard.color,
        ),
        body: ListView.builder(
          itemCount: widget.trip.locations.length,
          itemBuilder: (context, index) {
            var location = widget.trip.locations[index];
            return LocationCard(
              location: location,
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addLocation(context),
          backgroundColor: LocationsCard.color,
          child: const Icon(Icons.add),
        ));
  }

  void _addLocation(BuildContext context) async {
    LocationEntry? location = await showDialog(
        context: context, builder: (context) => const AddLocation());
    if (location == null) {
      return;
    }
    await api.addTripLocation(
        command: AddTripLocation(tripId: widget.trip.id, location: location));
  }
}

class LocationCard extends StatelessWidget {
  final Location location;

  const LocationCard({required this.location, super.key});

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.city,
                      style: textTheme.titleLarge,
                    ),
                    Text(
                      location.country,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ]),
            ),
            if (location.forecast != null)
              Expanded(child: LocationForecast(location.forecast!)),
          ],
        ),
      ),
    );
  }
}

class LocationForecast extends StatelessWidget {
  final WeatherForecast forecast;

  const LocationForecast(this.forecast, {super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
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
            ButtonBar(
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
