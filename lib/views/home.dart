import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api.dart';

import 'packing_list/packing_list_view.dart';
import 'trip/trip_overview.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    runBackgroundJobs();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Holiday Planner"),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "Trips", icon: Icon(Icons.work)),
              Tab(text: "Packing Lists", icon: Icon(Icons.checklist)),
            ],
          ),
        ),
        body: TabBarView(
            controller: _tabController,
            children: const [TripOverview(), PackingListView()]));
  }
}
