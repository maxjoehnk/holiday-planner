import 'package:flutter/material.dart';
import 'package:holiday_planner/ffi.dart';
import 'package:holiday_planner/views/trip/trip_summary.dart';
import 'package:palette_generator/palette_generator.dart';

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
      TransitsCard(),
      PointsOfInterestsCard(),
      AccommodationsCard(),
      WeatherCard(),
      LocationsCard(trip: widget.trip),
    ];
    _headerImage = widget.trip.headerImage != null
        ? MemoryImage(widget.trip.headerImage!)
        : null;
    PaletteGenerator.fromImageProvider(_headerImage!).then((value) {
      setState(() {
        _headerColor = value.vibrantColor;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                background:
                    Image.memory(widget.trip.headerImage!, fit: BoxFit.cover),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.all(4)),
          if (_selectedTab == 0) _tripSummary(),
          // if (_selectedTab == 1) TripTimeline(),
          if (_selectedTab == 2) _tripAttachments(),
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

  _tripSummary() {
    return SliverList(
        delegate: SliverChildBuilderDelegate(
      (context, index) {
        return summaryCards[index];
      },
      childCount: summaryCards.length,
    ));
  }

  _tripTimeline() {}

  _tripAttachments() {
    if (widget.trip.attachments.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text("No Attachments"),
        ),
      );
    }
    return SliverList(
        delegate: SliverChildBuilderDelegate(
      (context, index) {
        var attachment = widget.trip.attachments[index];
        return ListTile(
          title: Text(attachment.name),
        );
      },
      childCount: widget.trip.attachments.length,
    ));
  }
}
