import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holiday_planner/date_format.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/views/trip/attachments/add_attachment.dart';
import 'package:holiday_planner/views/trip/attachments/trip_attachments.dart';
import 'package:holiday_planner/views/trip/edit_trip.dart';
import 'package:holiday_planner/views/trip/summary/trip_summary.dart';
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
  late StreamController<TripOverviewModel> _trip;
  late Stream<TripOverviewModel> _trip$;

  @override
  void initState() {
    super.initState();
    _trip = StreamController();
    _trip$ = _trip.stream.asBroadcastStream();
    _trip$.forEach((trip) {
      _headerImage =
          trip.headerImage != null ? MemoryImage(trip.headerImage!) : null;
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

  String _buildDateString(TripOverviewModel trip) {
    final isSameDate = trip.startDate.year == trip.endDate.year &&
        trip.startDate.month == trip.endDate.month &&
        trip.startDate.day == trip.endDate.day;

    if (isSameDate) {
      return formatDate(trip.startDate);
    } else {
      return '${formatDate(trip.startDate)} - ${formatDate(trip.endDate)}';
    }
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
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 200,
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditTripView(trip: trip),
                              ),
                            )
                            .then((_) => _fetch());
                      },
                      tooltip: "Edit Trip",
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    title: Padding(
                      padding: const EdgeInsets.only(right: 48.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _buildDateString(trip),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  trip.durationDays == 1
                                      ? "1 day"
                                      : "${trip.durationDays} days",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                            ],
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
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.all(4)),
                if (_selectedTab == 0) TripSummary(trip, refresh: _fetch),
                if (_selectedTab == 1) TripTimeline(tripId: widget.tripId),
                if (_selectedTab == 2) TripAttachments(tripId: widget.tripId),
              ],
            );
          }),
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
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => AddAttachmentView(tripId: widget.tripId)));
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Attachment"),
      );
    }
    return null;
  }
}
