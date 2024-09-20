import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holiday_planner/colors.dart';
import 'package:holiday_planner/src/rust/api/accommodations.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/views/trip/accommodations/add_accommodation.dart';
import 'package:holiday_planner/views/trip/section_theme.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class TripAccommodations extends StatefulWidget {
  final UuidValue tripId;

  const TripAccommodations({super.key, required this.tripId});

  @override
  State<TripAccommodations> createState() => _TripAccommodationsState();
}

class _TripAccommodationsState extends State<TripAccommodations> {
  late StreamController<List<AccommodationModel>> _accommodations;
  late Stream<List<AccommodationModel>>? _accommodations$;

  @override
  void initState() {
    super.initState();
    _accommodations = StreamController();
    _accommodations$ = _accommodations.stream;
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return SectionTheme(
      color: ACCOMMODATIONS_COLOR,
      child: Scaffold(
          appBar: AppBar(
            title: const Text("Accommodations"),
          ),
          body: StreamBuilder(
              stream: _accommodations$,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  itemCount: snapshot.requireData.length,
                  itemBuilder: (context, index) {
                    var accommodation = snapshot.requireData[index];
                    return AccommodationCard(accommodation: accommodation);
                  },
                );
              }),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addAccommodation(context),
            child: const Icon(Icons.add),
          )),
    );
  }

  void _addAccommodation(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => AddAccommodation(tripId: widget.tripId)));
    _fetch();
  }

  _fetch() {
    _accommodations.addStream(getTripAccommodations(tripId: widget.tripId).asStream());
  }
}

class AccommodationCard extends StatelessWidget {
  final AccommodationModel accommodation;

  const AccommodationCard({required this.accommodation, super.key});

  @override
  Widget build(BuildContext context) {
    var checkIn = DateFormat.yMMMMd().format(accommodation.checkIn);
    var checkOut = DateFormat.yMMMMd().format(accommodation.checkOut);

    return Card(
      child: ListTile(
        title: Text(accommodation.name),
        subtitle: Text("$checkIn - $checkOut"),
      )
    );
  }
}
