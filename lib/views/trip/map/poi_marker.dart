import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:holiday_planner/colors.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:latlong2/latlong.dart';

class PointOfInterestMarker extends Marker {
  PointOfInterestMarker({ required PointOfInterestModel poi, final Function(PointOfInterestModel)? onTap })
      : super(
          point: poi.coordinates != null
              ? LatLng(poi.coordinates!.latitude, poi.coordinates!.longitude)
              : throw ArgumentError('PointOfInterestModel must have coordinates'),
          width: 40,
          height: 40,
          child: _PointOfInterestMarker(poi, onTap: onTap)
        );

}

class _PointOfInterestMarker extends StatelessWidget {
  final PointOfInterestModel poi;
  final Function(PointOfInterestModel)? onTap;

  const _PointOfInterestMarker(this.poi, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(poi),
      child: Container(
        decoration: BoxDecoration(
          color: POINTS_OF_INTERESTS_COLOR,
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
          Icons.place,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
