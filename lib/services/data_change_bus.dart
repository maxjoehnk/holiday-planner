import 'dart:async';
import 'dart:developer';

import 'package:holiday_planner/src/rust/api/events.dart';
import 'package:uuid/uuid.dart';

/// Singleton bridge that fans the Rust data-change stream out to
/// per-domain Dart streams that views can subscribe to.
class DataChangeBus {
  DataChangeBus._();
  static final DataChangeBus instance = DataChangeBus._();

  final StreamController<DataChangeEvent> _controller =
      StreamController<DataChangeEvent>.broadcast();
  StreamSubscription<DataChangeEvent>? _upstream;

  /// Connect to the Rust event stream. Idempotent; safe to call once at app start.
  void start() {
    if (_upstream != null) {
      return;
    }
    _connect();
  }

  void _connect() {
    _upstream = subscribeDataChanges().listen(
      _controller.add,
      onError: (Object error, StackTrace stack) {
        log('DataChangeBus upstream error: $error', stackTrace: stack);
      },
      onDone: () {
        _upstream = null;
        _connect();
      },
      cancelOnError: false,
    );
  }

  /// Raw event stream. Most callers want the filtered helpers below.
  Stream<DataChangeEvent> get events => _controller.stream;

  Stream<void> onTripsChanged() => events
      .where((e) => e is DataChangeEvent_TripsChanged)
      .map((_) => null);

  Stream<void> onTripChanged(UuidValue tripId) => events.where((e) {
        if (e is DataChangeEvent_TripChanged) {
          return e.tripId == tripId;
        }
        if (e is DataChangeEvent_TripsChanged) {
          return true;
        }
        return false;
      }).map((_) => null);

  Stream<void> onLocationsChanged(UuidValue tripId) => events.where((e) {
        if (e is DataChangeEvent_LocationsChanged) {
          return e.tripId == tripId;
        }
        return false;
      }).map((_) => null);

  Stream<void> onWeatherChanged(UuidValue tripId) => events.where((e) {
        if (e is DataChangeEvent_WeatherUpdated) {
          return e.tripId == tripId;
        }
        return false;
      }).map((_) => null);

  Stream<void> onTidesChanged(UuidValue tripId) => events.where((e) {
        if (e is DataChangeEvent_TidesUpdated) {
          return e.tripId == tripId;
        }
        return false;
      }).map((_) => null);

  /// Convenience: emits on either weather or tide updates for the given trip.
  Stream<void> onWeatherOrTidesChanged(UuidValue tripId) => events.where((e) {
        if (e is DataChangeEvent_WeatherUpdated) {
          return e.tripId == tripId;
        }
        if (e is DataChangeEvent_TidesUpdated) {
          return e.tripId == tripId;
        }
        return false;
      }).map((_) => null);

  Stream<void> onLocationDataChanged(UuidValue locationId) => events.where((e) {
        if (e is DataChangeEvent_WeatherUpdated) {
          return e.locationId == locationId;
        }
        if (e is DataChangeEvent_TidesUpdated) {
          return e.locationId == locationId;
        }
        return false;
      }).map((_) => null);

  Stream<void> onPackingListChanged({UuidValue? tripId}) => events.where((e) {
        if (e is DataChangeEvent_PackingListChanged) {
          if (tripId == null) {
            return true;
          }
          return e.tripId == null || e.tripId == tripId;
        }
        return false;
      }).map((_) => null);

  Stream<void> onAccommodationsChanged(UuidValue tripId) => events.where((e) {
        if (e is DataChangeEvent_AccommodationsChanged) {
          return e.tripId == null || e.tripId == tripId;
        }
        return false;
      }).map((_) => null);

  Stream<void> onBookingsChanged(UuidValue tripId) => events.where((e) {
        if (e is DataChangeEvent_BookingsChanged) {
          return e.tripId == null || e.tripId == tripId;
        }
        return false;
      }).map((_) => null);

  Stream<void> onTransitsChanged(UuidValue tripId) => events.where((e) {
        if (e is DataChangeEvent_TransitsChanged) {
          return e.tripId == null || e.tripId == tripId;
        }
        return false;
      }).map((_) => null);

  Stream<void> onPoisChanged(UuidValue tripId) => events.where((e) {
        if (e is DataChangeEvent_PoisChanged) {
          return e.tripId == null || e.tripId == tripId;
        }
        return false;
      }).map((_) => null);

  Stream<void> onRoutesChanged(UuidValue tripId) => events.where((e) {
        if (e is DataChangeEvent_RoutesChanged) {
          return e.tripId == null || e.tripId == tripId;
        }
        return false;
      }).map((_) => null);

  Stream<void> onTripAttachmentsChanged(UuidValue tripId) => events.where((e) {
        if (e is DataChangeEvent_AttachmentsChanged) {
          return e.tripId == null || e.tripId == tripId;
        }
        return false;
      }).map((_) => null);

  Stream<void> onAccommodationAttachmentsChanged(UuidValue accommodationId) =>
      events.where((e) {
        if (e is DataChangeEvent_AttachmentsChanged) {
          return e.accommodationId == null ||
              e.accommodationId == accommodationId;
        }
        return false;
      }).map((_) => null);

  Stream<void> onTagsChanged() =>
      events.where((e) => e is DataChangeEvent_TagsChanged).map((_) => null);

  Stream<void> onTimelineChanged(UuidValue tripId) => events.where((e) {
        if (e is DataChangeEvent_TimelineChanged) {
          return e.tripId == tripId;
        }
        return false;
      }).map((_) => null);

  Stream<void> onTripDaysChanged(UuidValue tripId) => events.where((e) {
        if (e is DataChangeEvent_TripDaysChanged) {
          return e.tripId == tripId;
        }
        return false;
      }).map((_) => null);

  Stream<void> onAnyTripDataChanged(UuidValue tripId) => events.where((e) {
        bool matchesOptional(UuidValue? eventTripId) =>
            eventTripId == null || eventTripId == tripId;
        if (e is DataChangeEvent_TripChanged) return e.tripId == tripId;
        if (e is DataChangeEvent_TripsChanged) return true;
        if (e is DataChangeEvent_LocationsChanged) return e.tripId == tripId;
        if (e is DataChangeEvent_WeatherUpdated) return e.tripId == tripId;
        if (e is DataChangeEvent_TidesUpdated) return e.tripId == tripId;
        if (e is DataChangeEvent_PackingListChanged) {
          return matchesOptional(e.tripId);
        }
        if (e is DataChangeEvent_AccommodationsChanged) {
          return matchesOptional(e.tripId);
        }
        if (e is DataChangeEvent_BookingsChanged) {
          return matchesOptional(e.tripId);
        }
        if (e is DataChangeEvent_TransitsChanged) {
          return matchesOptional(e.tripId);
        }
        if (e is DataChangeEvent_PoisChanged) {
          return matchesOptional(e.tripId);
        }
        if (e is DataChangeEvent_RoutesChanged) {
          return matchesOptional(e.tripId);
        }
        if (e is DataChangeEvent_TripDaysChanged) {
          return e.tripId == tripId;
        }
        return false;
      }).map((_) => null);
}
