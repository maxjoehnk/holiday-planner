import 'package:flutter/material.dart';
import 'package:holiday_planner/colors.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:latlong2/latlong.dart';

import 'marker.dart';

class AccommodationMarker extends MapMarker {
  AccommodationMarker(
      {required AccommodationModel accommodation,
      final Function(AccommodationModel)? onTap})
      : super(
          point: accommodation.coordinates != null
              ? LatLng(accommodation.coordinates!.latitude,
                  accommodation.coordinates!.longitude)
              : throw ArgumentError('AccommodationModel must have coordinates'),
          color: ACCOMMODATIONS_COLOR,
          icon: Icons.hotel,
          onTap: onTap == null ? null : () => onTap(accommodation),
        );
}
