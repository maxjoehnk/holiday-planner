import 'package:flutter/material.dart';
import 'package:holiday_planner/l10n/app_localizations.dart';
import 'package:holiday_planner/services/data_change_bus.dart';
import 'package:holiday_planner/services/refreshable_data.dart';
import 'package:holiday_planner/src/rust/api/accommodations.dart';
import 'package:holiday_planner/src/rust/api/bookings.dart';
import 'package:holiday_planner/src/rust/api/points_of_interest.dart';
import 'package:holiday_planner/src/rust/api/routes.dart';
import 'package:holiday_planner/src/rust/api/transits.dart';
import 'package:holiday_planner/src/rust/api/trip_days.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:holiday_planner/src/rust/commands/trip_day.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/src/rust/models/bookings.dart';
import 'package:holiday_planner/src/rust/models/trip_day.dart';
import 'package:holiday_planner/views/trip/accommodations/edit_accommodation.dart';
import 'package:holiday_planner/views/trip/activities/edit_point_of_interest.dart';
import 'package:holiday_planner/views/trip/activities/route_detail.dart';
import 'package:holiday_planner/views/trip/bookings/edit_car_rental.dart';
import 'package:holiday_planner/views/trip/bookings/edit_reservation.dart';
import 'package:holiday_planner/views/trip/transits/edit_train.dart';
import 'package:uuid/uuid.dart';

import 'add_to_day_sheet.dart';
import 'day_card.dart';
import 'day_picker_sheet.dart';
import 'day_planner_types.dart';
import 'unassigned_panel.dart';

class _PlannerData {
  final List<TripDayView> days;
  final UnassignedItems unassigned;

  const _PlannerData(this.days, this.unassigned);
}

class DayPlannerView extends StatefulWidget {
  final UuidValue tripId;

  const DayPlannerView({super.key, required this.tripId});

  @override
  State<DayPlannerView> createState() => _DayPlannerViewState();
}

class _DayPlannerViewState extends State<DayPlannerView> {
  late final RefreshableData<_PlannerData> _data;

  @override
  void initState() {
    super.initState();
    _data = RefreshableData<_PlannerData>(
      fetch: _fetch,
      refreshOn: [DataChangeBus.instance.onAnyTripDataChanged(widget.tripId)],
    );
  }

  Future<_PlannerData> _fetch() async {
    final days = await getTripDays(tripId: widget.tripId);
    final unassigned = await getUnassignedDayItems(tripId: widget.tripId);
    return _PlannerData(days, unassigned);
  }

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  Future<void> _assign(
      SchedulableItemType type, UuidValue itemId, DateTime date) async {
    await assignItemToDay(
      command: AssignItemToDay(
        tripId: widget.tripId,
        itemType: type,
        itemId: itemId,
        date: date,
      ),
    );
  }

  Future<void> _unassign(SchedulableItemType type, UuidValue itemId) async {
    await unassignDayItem(
      tripId: widget.tripId,
      command: UnassignItem(itemType: type, itemId: itemId),
    );
  }

  Future<void> _handleTitle(TripDayView day, String? title) async {
    await setTripDayTitle(
      command: SetTripDayTitle(
        tripId: widget.tripId,
        date: day.date,
        title: title,
      ),
    );
  }

  Future<DateTime?> _pickDay({DateTime? excludeDate, required String title}) async {
    final days = _currentDays();
    if (!mounted) {
      return null;
    }
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DayPickerSheet(
        days: days,
        excludeDate: excludeDate,
        title: title,
      ),
    );
  }

  List<TripDayView> _currentDays() {
    // The stream's latest snapshot is held inside StreamBuilder; cache via _lastData.
    return _lastData?.days ?? const [];
  }

  UnassignedItems _currentUnassigned() {
    return _lastData?.unassigned ??
        const UnassignedItems(pointsOfInterest: [], routes: []);
  }

  _PlannerData? _lastData;

  Future<void> _openAddSheet(TripDayView day) async {
    final loc = AppLocalizations.of(context)!;
    final selection = await showModalBottomSheet<AddToDaySelection>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddToDaySheet(
        targetDay: day,
        unassigned: _currentUnassigned(),
        allDays: _currentDays(),
      ),
    );
    if (selection == null) {
      return;
    }
    await _assign(selection.type, selection.itemId, day.date);
    if (!mounted) {
      return;
    }
    if (selection.sourceDayId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.dayPlannerMoveToDay)),
      );
    }
  }

  Future<void> _openMoveSheet(
      SchedulableItemType type, UuidValue itemId, TripDayView sourceDay) async {
    final loc = AppLocalizations.of(context)!;
    final date = await _pickDay(
      excludeDate: sourceDay.date,
      title: loc.dayPlannerMoveToDay,
    );
    if (date == null) {
      return;
    }
    await _assign(type, itemId, date);
  }

  Future<void> _openAssignFromUnassigned(
      SchedulableItemType type, UuidValue itemId) async {
    final loc = AppLocalizations.of(context)!;
    final date = await _pickDay(
      title: loc.dayPlannerAddToDay,
    );
    if (date == null) {
      return;
    }
    await _assign(type, itemId, date);
  }

  Future<void> _openItemDetail(DayItemDetails details) async {
    final navigator = Navigator.of(context);
    final tripId = widget.tripId;
    final route = await details.map(
      pointOfInterest: (d) async {
        final list = await getTripPointsOfInterest(tripId: tripId);
        final match = list.where((poi) => poi.id == d.id).firstOrNull;
        if (match == null) {
          return null;
        }
        return MaterialPageRoute(
          builder: (_) => EditPointOfInterest(pointOfInterest: match),
        );
      },
      route: (d) async {
        final list = await getTripRoutes(tripId: tripId);
        final match = list.where((r) => r.id == d.id).firstOrNull;
        if (match == null) {
          return null;
        }
        return MaterialPageRoute(builder: (_) => RouteDetail(route: match));
      },
      accommodationCheckIn: (d) =>
          _accommodationRoute(tripId, d.accommodationId),
      accommodationCheckOut: (d) =>
          _accommodationRoute(tripId, d.accommodationId),
      accommodationStay: (d) =>
          _accommodationRoute(tripId, d.accommodationId),
      trainDeparture: (d) => _trainRoute(tripId, d.trainId),
      trainArrival: (d) => _trainRoute(tripId, d.trainId),
      reservation: (d) => _reservationRoute(tripId, d.reservationId),
      carRentalPickUp: (d) => _carRentalRoute(tripId, d.carRentalId),
      carRentalDropOff: (d) => _carRentalRoute(tripId, d.carRentalId),
    );
    if (!mounted || route == null) {
      return;
    }
    await navigator.push(route);
  }

  Future<MaterialPageRoute?> _accommodationRoute(
      UuidValue tripId, UuidValue id) async {
    final list = await getTripAccommodations(tripId: tripId);
    final match = list.where((a) => a.id == id).firstOrNull;
    if (match == null) {
      return null;
    }
    return MaterialPageRoute(builder: (_) => EditAccommodation(tripId: tripId, accommodation: match));
  }

  Future<MaterialPageRoute?> _trainRoute(
      UuidValue tripId, UuidValue id) async {
    final list = await getTripTrains(tripId: tripId);
    final match = list.where((t) => t.id == id).firstOrNull;
    if (match == null) {
      return null;
    }
    return MaterialPageRoute(builder: (_) => EditTrainPage(train: match));
  }

  Future<MaterialPageRoute?> _reservationRoute(
      UuidValue tripId, UuidValue id) async {
    final list = await getTripBookings(tripId: tripId);
    for (final booking in list) {
      if (booking is Booking_Reservation && booking.field0.id == id) {
        return MaterialPageRoute(
          builder: (_) => EditReservationPage(reservation: booking.field0),
        );
      }
    }
    return null;
  }

  Future<MaterialPageRoute?> _carRentalRoute(
      UuidValue tripId, UuidValue id) async {
    final list = await getTripBookings(tripId: tripId);
    for (final booking in list) {
      if (booking is Booking_CarRental && booking.field0.id == id) {
        return MaterialPageRoute(
          builder: (_) => EditCarRentalPage(carRental: booking.field0),
        );
      }
    }
    return null;
  }

  Future<void> _openLocationsSheet(TripDayView day) async {
    final locations = await getTripLocations(tripId: widget.tripId);
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _LocationsSheet(
        tripId: widget.tripId,
        day: day,
        tripLocations: locations,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<_PlannerData>(
      stream: _data.stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                AppLocalizations.of(context)!
                    .errorWithMessage(snapshot.error.toString()),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(64),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        _lastData = snapshot.requireData;
        final data = _lastData!;
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),
              UnassignedPanel(
                items: data.unassigned,
                onAssign: _openAssignFromUnassigned,
                onItemDropped: (dragged) {
                  if (dragged.sourceDayId == null) {
                    return;
                  }
                  _unassign(dragged.type, dragged.itemId);
                },
              ),
              ...data.days.map((day) => DayCard(
                    day: day,
                    onTitleChanged: (title) => _handleTitle(day, title),
                    onAddPressed: () => _openAddSheet(day),
                    onEditLocations: () => _openLocationsSheet(day),
                    onUnassign: _unassign,
                    onMove: (type, itemId) =>
                        _openMoveSheet(type, itemId, day),
                    onItemTap: _openItemDetail,
                    onItemDropped: (dragged) =>
                        _assign(dragged.type, dragged.itemId, day.date),
                  )),
              const SizedBox(height: 32),
            ]),
          ),
        );
      },
    );
  }
}

class _LocationsSheet extends StatefulWidget {
  final UuidValue tripId;
  final TripDayView day;
  final List<TripLocationListModel> tripLocations;

  const _LocationsSheet({
    required this.tripId,
    required this.day,
    required this.tripLocations,
  });

  @override
  State<_LocationsSheet> createState() => _LocationsSheetState();
}

class _LocationsSheetState extends State<_LocationsSheet> {
  late List<DayLocation> _current;

  @override
  void initState() {
    super.initState();
    _current = List.of(widget.day.locations);
  }

  bool _has(UuidValue id) => _current.any((l) => l.locationId == id);

  bool _isPrimary(UuidValue id) =>
      _current.any((l) => l.locationId == id && l.isPrimary);

  Future<void> _toggle(TripLocationListModel location) async {
    final present = _has(location.id);
    if (present) {
      final dayId = widget.day.id;
      if (dayId == null) {
        return;
      }
      await removeTripDayLocation(
        tripId: widget.tripId,
        command: RemoveTripDayLocation(
          tripDayId: dayId,
          locationId: location.id,
        ),
      );
      setState(() {
        _current.removeWhere((l) => l.locationId == location.id);
        if (_current.isNotEmpty && !_current.any((l) => l.isPrimary)) {
          final first = _current.first;
          _current[0] = DayLocation(
            locationId: first.locationId,
            city: first.city,
            country: first.country,
            coordinates: first.coordinates,
            isPrimary: true,
          );
        }
      });
    } else {
      await addTripDayLocation(
        command: AddTripDayLocation(
          tripId: widget.tripId,
          date: widget.day.date,
          locationId: location.id,
        ),
      );
      setState(() {
        final isFirst = _current.isEmpty;
        _current.add(DayLocation(
          locationId: location.id,
          city: location.city,
          country: location.country,
          coordinates: location.coordinates,
          isPrimary: isFirst,
        ));
      });
    }
  }

  Future<void> _setPrimary(UuidValue locationId) async {
    final dayId = widget.day.id;
    if (dayId == null) {
      return;
    }
    await setPrimaryTripDayLocation(
      tripId: widget.tripId,
      command: SetPrimaryTripDayLocation(
        tripDayId: dayId,
        locationId: locationId,
      ),
    );
    setState(() {
      _current = _current
          .map((l) => DayLocation(
                locationId: l.locationId,
                city: l.city,
                country: l.country,
                coordinates: l.coordinates,
                isPrimary: l.locationId == locationId,
              ))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.dayPlannerLocationsSheetTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (widget.tripLocations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'This trip has no locations yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.tripLocations.length,
                  itemBuilder: (context, index) {
                    final location = widget.tripLocations[index];
                    final present = _has(location.id);
                    final isPrimary = _isPrimary(location.id);
                    return ListTile(
                      onTap: () => _toggle(location),
                      leading: Icon(
                        present
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: present
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(
                          '${location.city}${location.country.isEmpty ? '' : ', ${location.country}'}'),
                      trailing: present
                          ? IconButton(
                              tooltip: loc.dayPlannerPrimaryBadge,
                              icon: Icon(
                                isPrimary
                                    ? Icons.star
                                    : Icons.star_border,
                                color: isPrimary
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                              onPressed: isPrimary
                                  ? null
                                  : () => _setPrimary(location.id),
                            )
                          : null,
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
