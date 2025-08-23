import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:holiday_planner/views/trip/map/location_details.dart';
import 'package:holiday_planner/views/trip/map/location_marker.dart';
import 'package:holiday_planner/views/trip/map/poi_details.dart';
import 'package:holiday_planner/views/trip/map/poi_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:holiday_planner/src/rust/api/points_of_interest.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:uuid/uuid.dart';

class TripMap extends StatefulWidget {
  final UuidValue tripId;

  const TripMap({super.key, required this.tripId});

  @override
  State<TripMap> createState() => _TripMapState();
}

class _TripMapState extends State<TripMap> {
  late StreamController<List<TripLocationListModel>> _locations;
  late Stream<List<TripLocationListModel>>? _locations$;
  late StreamController<List<PointOfInterestModel>> _pointsOfInterest;
  late Stream<List<PointOfInterestModel>>? _pointsOfInterest$;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _locations = StreamController();
    _locations$ = _locations.stream;
    _pointsOfInterest = StreamController();
    _pointsOfInterest$ = _pointsOfInterest.stream;
    _fetch();
  }

  @override
  void activate() {
    super.activate();
    _fetch();
  }

  @override
  void reassemble() {
    super.reassemble();
    _fetch();
  }

  @override
  void dispose() {
    _locations.close();
    _pointsOfInterest.close();
    super.dispose();
  }

  void _fetch() {
    _locations.addStream(getTripLocations(tripId: widget.tripId).asStream());
    _pointsOfInterest.addStream(getTripPointsOfInterest(tripId: widget.tripId).asStream());
  }

  List<Marker> _buildLocationMarkers(List<TripLocationListModel> locations) {
    return locations.map((location) {
      return LocationMarker(
        location: location,
        onTap: (loc) => _showLocationDetails(loc),
      );
    }).toList();
  }

  List<Marker> _buildPoiMarkers(List<PointOfInterestModel> pois) {
    return pois
        .where((poi) => poi.coordinates != null)
        .map((poi) => PointOfInterestMarker(poi: poi, onTap: (poi) => _showPoiDetails(poi)))
        .toList();
  }

  void _showPoiDetails(PointOfInterestModel poi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        builder: (context, scrollController) => PointOfInterestMapDetails(poi: poi, scrollController: scrollController),
      ),
    );
  }

  void _showLocationDetails(TripLocationListModel location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        builder: (context, scrollController) =>
            LocationMapDetails(location: location, scrollController: scrollController),
      ),
    );
  }

  LatLng _calculateCenter(List<TripLocationListModel> locations, List<PointOfInterestModel> pois) {
    List<LatLng> allPoints = [];

    for (var location in locations) {
      allPoints.add(LatLng(location.coordinates.latitude, location.coordinates.longitude));
    }

    for (var poi in pois) {
      if (poi.coordinates != null) {
        allPoints.add(LatLng(poi.coordinates!.latitude, poi.coordinates!.longitude));
      }
    }

    if (allPoints.isEmpty) {
      return const LatLng(0, 0);
    }

    double sumLat = 0;
    double sumLng = 0;
    for (var point in allPoints) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }

    return LatLng(sumLat / allPoints.length, sumLng / allPoints.length);
  }

  double _calculateZoom(List<TripLocationListModel> locations, List<PointOfInterestModel> pois) {
    List<LatLng> allPoints = [];

    for (var location in locations) {
      allPoints.add(LatLng(location.coordinates.latitude, location.coordinates.longitude));
    }

    for (var poi in pois) {
      if (poi.coordinates != null) {
        allPoints.add(LatLng(poi.coordinates!.latitude, poi.coordinates!.longitude));
      }
    }

    if (allPoints.length <= 1) {
      return 10.0;
    }

    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (var point in allPoints) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    double latDiff = maxLat - minLat;
    double lngDiff = maxLng - minLng;
    double maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    if (maxDiff < 0.1) return 12.0;
    if (maxDiff < 1.0) return 10.0;
    if (maxDiff < 5.0) return 8.0;
    if (maxDiff < 20.0) return 6.0;
    return 4.0;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TripLocationListModel>>(
        stream: _locations$,
        builder: (context, locationsSnapshot) {
          return StreamBuilder<List<PointOfInterestModel>>(
            stream: _pointsOfInterest$,
            builder: (context, poisSnapshot) {
              if (locationsSnapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading locations',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            locationsSnapshot.error.toString(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (!locationsSnapshot.hasData) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(64.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              final locations = locationsSnapshot.requireData;
              final pois = poisSnapshot.data ?? [];

              if (locations.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No locations found',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add some locations to your trip to see them on the map.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final center = _calculateCenter(locations, pois);
              final zoom = _calculateZoom(locations, pois);
              final markers = [..._buildLocationMarkers(locations), ..._buildPoiMarkers(pois)];

              return SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 300,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: zoom,
                      minZoom: 1.0,
                      maxZoom: 18.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'me.maxjoehnk.holiday_planner',
                      ),
                      MarkerLayer(markers: markers),
                      const SimpleAttributionWidget(source: Text("OpenStreetMap Contributors")),
                    ],
                  ),
                ),
              );
            },
          );
        });
  }
}
