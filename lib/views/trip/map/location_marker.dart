import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:holiday_planner/colors.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:latlong2/latlong.dart';

class LocationMarker extends Marker {
  LocationMarker(
      {required TripLocationListModel location, final Function(TripLocationListModel)? onTap})
      : super(
            point: LatLng(location.coordinates.latitude, location.coordinates.longitude),
            width: 40,
            height: 40,
            child: _LocationMarker(location, onTap: onTap));
}

class _LocationMarker extends StatelessWidget {
  final TripLocationListModel location;
  final Function(TripLocationListModel)? onTap;

  const _LocationMarker(this.location, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(location),
      child: Container(
        decoration: BoxDecoration(
          color: LOCATIONS_COLOR,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.location_on,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
