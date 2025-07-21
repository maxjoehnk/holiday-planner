import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/views/trip/attachments/add_attachment.dart';
import 'package:holiday_planner/views/trip/attachments/trip_attachments.dart';
import 'package:holiday_planner/views/trip/edit_trip.dart';
import 'package:holiday_planner/views/trip/summary/trip_summary.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:uuid/uuid.dart';

import 'timeline/trip_timeline.dart';

class TripView extends StatefulWidget {
  final UuidValue tripId;

  const TripView({required this.tripId, super.key});

  @override
  State<TripView> createState() => _TripViewState();
}

class _TripViewState extends State<TripView> {
  int _selectedTab = 0;
  ImageProvider? _headerImage;
  PaletteColor? _headerColor = PaletteColor(Colors.teal, 1);
  late StreamController<TripOverviewModel> _trip;
  late Stream<TripOverviewModel> _trip$;

  @override
  void initState() {
    super.initState();
    _trip = StreamController();
    _trip$ = _trip.stream.asBroadcastStream();
    _trip$.forEach((trip) {
      _headerImage = trip.headerImage != null
          ? MemoryImage(trip.headerImage!)
          : null;
      if (_headerImage != null) {
        PaletteGenerator.fromImageProvider(_headerImage!).then((value) {
          setState(() {
            _headerColor = value.vibrantColor;
          });
        });
      }
    });

    _fetch();
  }

  @override
  void activate() {
    super.activate();
    _fetch();
  }

  @override
  void reassemble() {
    super.reassemble();
    _fetch();
  }


  void _fetch() {
    _trip.addStream(getTrip(id: widget.tripId).asStream());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _fab(),
      body: StreamBuilder(
        stream: _trip$,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var trip = snapshot.requireData;
          return CustomScrollView(
            slivers: [
              Theme(
                data: ThemeData(
                    primaryIconTheme:
                        IconThemeData(color: _headerColor?.titleTextColor)),
                child: SliverAppBar(
                  backgroundColor: _headerColor?.color,
                  titleTextStyle: TextStyle(color: _headerColor?.titleTextColor),
                  pinned: true,
                  expandedHeight: 200,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditTripView(trip: trip),
                          ),
                        ).then((_) => _fetch());
                      },
                      tooltip: "Edit Trip",
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      trip.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: const Offset(1.0, 1.0),
                            blurRadius: 3.0,
                            color: Colors.black.withOpacity(0.8),
                          ),
                          Shadow(
                            offset: const Offset(-1.0, -1.0),
                            blurRadius: 3.0,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ],
                      ),
                    ),
                    background: _headerImage == null 
                        ? null 
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              Image(image: _headerImage!, fit: BoxFit.cover),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.3),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.all(4)),
              if (_selectedTab == 0) TripSummary(trip, refresh: _fetch),
              if (_selectedTab == 1) TripTimeline(tripId: widget.tripId),
              if (_selectedTab == 2) TripAttachments(tripId: widget.tripId),
            ],
          );
        }
      ),
      bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedTab,
          onTap: (i) => setState(() {
                _selectedTab = i;
              }),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard), label: "Summary"),
            BottomNavigationBarItem(
                icon: Icon(Icons.timeline), label: "Timeline"),
            BottomNavigationBarItem(
                icon: Icon(Icons.attachment), label: "Attachments"),
          ]),
    );
  }

  Widget? _fab() {
    if (_selectedTab == 2) {
      return FloatingActionButton.extended(
        heroTag: "trip_view_fab",
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddAttachmentView(tripId: widget.tripId)));
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Attachment"),
      );
    }
    return null;
  }
}
