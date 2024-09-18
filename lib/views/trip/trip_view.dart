import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/views/trip/add_attachment.dart';
import 'package:holiday_planner/views/trip/trip_attachments.dart';
import 'package:holiday_planner/views/trip/trip_summary.dart';
import 'package:palette_generator/palette_generator.dart';

import 'trip_timeline.dart';

class TripView extends StatefulWidget {
  final Trip trip;

  const TripView({required this.trip, super.key});

  @override
  State<TripView> createState() => _TripViewState();
}

class _TripViewState extends State<TripView> {
  int _selectedTab = 0;
  ImageProvider? _headerImage;
  PaletteColor? _headerColor;
  List<Widget> summaryCards = [];

  @override
  void initState() {
    super.initState();
    summaryCards = [
      PackingListCard(trip: widget.trip),
      const TransitsCard(),
      const PointsOfInterestsCard(),
      const AccommodationsCard(),
      const WeatherCard(),
      LocationsCard(trip: widget.trip),
    ];
    _headerImage = widget.trip.headerImage != null
        ? MemoryImage(widget.trip.headerImage!)
        : null;
    if (_headerImage != null) {
      PaletteGenerator.fromImageProvider(_headerImage!).then((value) {
        setState(() {
          _headerColor = value.vibrantColor;
        });
      });
    }else {
      _headerColor = PaletteColor(Colors.teal, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _fab(),
      body: CustomScrollView(
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
              flexibleSpace: FlexibleSpaceBar(
                title: Text(widget.trip.name),
                background: widget.trip.headerImage == null ? null :
                    Image.memory(widget.trip.headerImage!, fit: BoxFit.cover),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.all(4)),
          if (_selectedTab == 0) _tripSummary(),
          if (_selectedTab == 1) TripTimeline(trip: widget.trip),
          if (_selectedTab == 2) TripAttachments(trip: widget.trip),
        ],
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
                icon: Icon(Icons.confirmation_num), label: "Attachments"),
          ]),
    );
  }

  Widget? _fab() {
    if (_selectedTab == 2) {
      return FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddAttachmentView(tripId: widget.trip.id)));
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Attachment"),
      );
    }
    return null;
  }

  _tripSummary() {
    return SliverList(
        delegate: SliverChildBuilderDelegate(
      (context, index) {
        return summaryCards[index];
      },
      childCount: summaryCards.length,
    ));
  }
}
