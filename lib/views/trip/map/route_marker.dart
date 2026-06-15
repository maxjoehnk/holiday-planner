import 'package:flutter/material.dart';
import 'package:holiday_planner/colors.dart';
import 'package:holiday_planner/src/rust/models/routes.dart';
import 'package:latlong2/latlong.dart';

import 'marker.dart';

class RouteMarker extends MapMarker {
  RouteMarker({required RouteModel route, final Function(RouteModel)? onTap})
      : super(
          point: LatLng(
            route.startCoordinate.latitude,
            route.startCoordinate.longitude,
          ),
          color: ACTIVITIES_COLOR,
          icon: Icons.hiking,
          onTap: onTap == null ? null : () => onTap(route),
        );
}
