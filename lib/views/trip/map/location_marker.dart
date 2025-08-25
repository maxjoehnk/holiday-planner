import 'package:holiday_planner/colors.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:latlong2/latlong.dart';

import 'marker.dart';

class LocationMarker extends MapMarker {
  LocationMarker(
      {required TripLocationListModel location, final Function(TripLocationListModel)? onTap})
      : super(
            point: LatLng(location.coordinates.latitude, location.coordinates.longitude),
            color: LOCATIONS_COLOR,
            onTap: onTap == null ? null : () => onTap(location));
}
