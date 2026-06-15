import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:holiday_planner/services/data_change_bus.dart';
import 'package:holiday_planner/services/map_tile_cache.dart';
import 'package:holiday_planner/services/refreshable_data.dart';
import 'package:holiday_planner/views/trip/accommodations/edit_accommodation.dart';
import 'package:holiday_planner/views/trip/activities/edit_point_of_interest.dart';
import 'package:holiday_planner/views/trip/activities/route_detail.dart';
import 'package:holiday_planner/views/trip/locations/location_detail_view.dart';
import 'package:holiday_planner/views/trip/map/accommodation_details.dart';
import 'package:holiday_planner/views/trip/map/accommodation_marker.dart';
import 'package:holiday_planner/views/trip/map/location_details.dart';
import 'package:holiday_planner/views/trip/map/location_marker.dart';
import 'package:holiday_planner/views/trip/map/poi_details.dart';
import 'package:holiday_planner/views/trip/map/poi_marker.dart';
import 'package:holiday_planner/views/trip/map/route_details.dart';
import 'package:holiday_planner/views/trip/map/route_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:holiday_planner/src/rust/api/accommodations.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:holiday_planner/src/rust/api/points_of_interest.dart';
import 'package:holiday_planner/src/rust/api/routes.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/src/rust/models/routes.dart';
import 'package:uuid/uuid.dart';

class TripMap extends StatefulWidget {
  final UuidValue tripId;

  const TripMap({super.key, required this.tripId});

  @override
  State<TripMap> createState() => _TripMapState();
}

class _TripMapState extends State<TripMap> {
  late final _locations = RefreshableData<List<TripLocationListModel>>(
    fetch: () => getTripLocations(tripId: widget.tripId),
    refreshOn: [DataChangeBus.instance.onLocationsChanged(widget.tripId)],
  );
  late final _pointsOfInterest = RefreshableData<List<PointOfInterestModel>>(
    fetch: () => getTripPointsOfInterest(tripId: widget.tripId),
    refreshOn: [DataChangeBus.instance.onPoisChanged(widget.tripId)],
  );
  late final _routes = RefreshableData<List<RouteModel>>(
    fetch: () => getTripRoutes(tripId: widget.tripId),
    refreshOn: [DataChangeBus.instance.onRoutesChanged(widget.tripId)],
  );
  late final _accommodations = RefreshableData<List<AccommodationModel>>(
    fetch: () => getTripAccommodations(tripId: widget.tripId),
    refreshOn: [DataChangeBus.instance.onAccommodationsChanged(widget.tripId)],
  );
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _locations.dispose();
    _pointsOfInterest.dispose();
    _routes.dispose();
    _accommodations.dispose();
    super.dispose();
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

  List<Marker> _buildAccommodationMarkers(List<AccommodationModel> accommodations) {
    return accommodations
        .where((a) => a.coordinates != null)
        .map((a) => AccommodationMarker(
              accommodation: a,
              onTap: (a) => _showAccommodationDetails(a),
            ))
        .toList();
  }

  List<Polyline> _buildRoutePolylines(List<RouteModel> routes) {
    final colorScheme = Theme.of(context).colorScheme;
    return routes
        .where((r) => r.polyline.length >= 2)
        .map((route) => Polyline(
              points: route.polyline
                  .map((p) => LatLng(p.coordinate.latitude, p.coordinate.longitude))
                  .toList(),
              strokeWidth: 4.0,
              color: _colorForSport(route.sport, colorScheme),
            ))
        .toList();
  }

  List<Marker> _buildRouteStartMarkers(List<RouteModel> routes) {
    return routes
        .map((route) => RouteMarker(
              route: route,
              onTap: (r) => _openRouteDetail(r),
            ))
        .toList();
  }

  Color _colorForSport(String? sport, ColorScheme colorScheme) {
    if (sport == null) {
      return colorScheme.primary;
    }
    final s = sport.toLowerCase();
    if (s.contains("hike")) return Colors.green.shade700;
    if (s.contains("mtb") || s.contains("mountain")) return Colors.orange.shade700;
    if (s.contains("bike") || s.contains("cycle")) return Colors.blue.shade700;
    return colorScheme.primary;
  }

  void _showDetailsSheet(
      Widget Function(BuildContext sheetContext, ScrollController controller)
          builder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        builder: (context, scrollController) =>
            builder(sheetContext, scrollController),
      ),
    );
  }

  void _editFromSheet(BuildContext sheetContext, MaterialPageRoute route) {
    final navigator = Navigator.of(context);
    Navigator.of(sheetContext).pop();
    navigator.push(route);
  }

  void _openRouteDetail(RouteModel route) {
    _showDetailsSheet(
      (sheetContext, scrollController) => RouteMapDetails(
        route: route,
        scrollController: scrollController,
        onEdit: () => _editFromSheet(
          sheetContext,
          MaterialPageRoute(builder: (_) => RouteDetail(route: route)),
        ),
      ),
    );
  }

  void _showPoiDetails(PointOfInterestModel poi) {
    _showDetailsSheet(
      (sheetContext, scrollController) => PointOfInterestMapDetails(
        poi: poi,
        scrollController: scrollController,
        onEdit: () => _editFromSheet(
          sheetContext,
          MaterialPageRoute(
              builder: (_) => EditPointOfInterest(pointOfInterest: poi)),
        ),
      ),
    );
  }

  void _showAccommodationDetails(AccommodationModel accommodation) {
    _showDetailsSheet(
      (sheetContext, scrollController) => AccommodationMapDetails(
        accommodation: accommodation,
        scrollController: scrollController,
        onEdit: () => _editFromSheet(
          sheetContext,
          MaterialPageRoute(
            builder: (_) => EditAccommodation(
                tripId: widget.tripId, accommodation: accommodation),
          ),
        ),
      ),
    );
  }

  void _showLocationDetails(TripLocationListModel location) {
    _showDetailsSheet(
      (sheetContext, scrollController) => LocationMapDetails(
        location: location,
        scrollController: scrollController,
        onEdit: () => _editFromSheet(
          sheetContext,
          MaterialPageRoute(
              builder: (_) => LocationDetailView(locationId: location.id)),
        ),
      ),
    );
  }

  List<LatLng> _collectPoints(
    List<TripLocationListModel> locations,
    List<PointOfInterestModel> pois,
    List<RouteModel> routes,
    List<AccommodationModel> accommodations,
  ) {
    final all = <LatLng>[];
    for (final location in locations) {
      all.add(LatLng(location.coordinates.latitude, location.coordinates.longitude));
    }
    for (final poi in pois) {
      if (poi.coordinates != null) {
        all.add(LatLng(poi.coordinates!.latitude, poi.coordinates!.longitude));
      }
    }
    for (final route in routes) {
      all.add(LatLng(route.startCoordinate.latitude, route.startCoordinate.longitude));
    }
    for (final accommodation in accommodations) {
      if (accommodation.coordinates != null) {
        all.add(LatLng(accommodation.coordinates!.latitude, accommodation.coordinates!.longitude));
      }
    }
    return all;
  }

  LatLng _calculateCenter(
    List<TripLocationListModel> locations,
    List<PointOfInterestModel> pois,
    List<RouteModel> routes,
    List<AccommodationModel> accommodations,
  ) {
    final allPoints = _collectPoints(locations, pois, routes, accommodations);

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

  double _calculateZoom(
    List<TripLocationListModel> locations,
    List<PointOfInterestModel> pois,
    List<RouteModel> routes,
    List<AccommodationModel> accommodations,
  ) {
    final allPoints = _collectPoints(locations, pois, routes, accommodations);

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
        stream: _locations.stream,
        builder: (context, locationsSnapshot) {
          return StreamBuilder<List<PointOfInterestModel>>(
            stream: _pointsOfInterest.stream,
            builder: (context, poisSnapshot) {
              return StreamBuilder<List<RouteModel>>(
                stream: _routes.stream,
                builder: (context, routesSnapshot) {
                  return StreamBuilder<List<AccommodationModel>>(
                    stream: _accommodations.stream,
                    builder: (context, accommodationsSnapshot) {
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
              final routes = routesSnapshot.data ?? [];
              final accommodations = accommodationsSnapshot.data ?? [];

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

              final center = _calculateCenter(locations, pois, routes, accommodations);
              final zoom = _calculateZoom(locations, pois, routes, accommodations);
              final markers = [
                ..._buildLocationMarkers(locations),
                ..._buildPoiMarkers(pois),
                ..._buildRouteStartMarkers(routes),
                ..._buildAccommodationMarkers(accommodations),
              ];
              final polylines = _buildRoutePolylines(routes);

              return SliverFillRemaining(
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
                      tileProvider: FMTCTileProvider(
                        stores: {mapTileStore.storeName: BrowseStoreStrategy.readUpdateCreate},
                      ),
                    ),
                    if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
                    MarkerLayer(markers: markers),
                    const SimpleAttributionWidget(source: Text("OpenStreetMap Contributors")),
                  ],
                ),
              );
                    },
                  );
                },
              );
            },
          );
        });
  }
}
