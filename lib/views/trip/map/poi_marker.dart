import 'package:flutter/material.dart';
import 'package:holiday_planner/colors.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:latlong2/latlong.dart';

import 'marker.dart';

class PointOfInterestMarker extends MapMarker {
  PointOfInterestMarker({ required PointOfInterestModel poi, final Function(PointOfInterestModel)? onTap })
      : super(
          point: poi.coordinates != null
              ? LatLng(poi.coordinates!.latitude, poi.coordinates!.longitude)
              : throw ArgumentError('PointOfInterestModel must have coordinates'),
          color: ACTIVITIES_COLOR,
          icon: Icons.explore,
          onTap: onTap == null ? null : () => onTap(poi),
        );
}
