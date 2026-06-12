import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api.dart';
import 'package:holiday_planner/views/settings/settings_view.dart';

import 'packing_list/packing_list_view.dart';
import 'trip_list/trip_overview.dart';

const Duration _periodicRefreshInterval = Duration(minutes: 30);
const Duration _resumeDebounce = Duration(minutes: 2);

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  Timer? _refreshTimer;
  DateTime? _lastRun;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _triggerBackgroundJobs(force: true);
    _refreshTimer = Timer.periodic(_periodicRefreshInterval, (_) {
      _triggerBackgroundJobs(force: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _triggerBackgroundJobs();
    }
  }

  void _triggerBackgroundJobs({bool force = false}) {
    final now = DateTime.now();
    if (!force && _lastRun != null && now.difference(_lastRun!) < _resumeDebounce) {
      return;
    }
    _lastRun = now;
    runBackgroundJobs().catchError((Object error, StackTrace stack) {
      log('runBackgroundJobs failed: $error', stackTrace: stack);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Holiday Planner"),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsView()));
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          TripOverview(),
          PackingListView(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.luggage_outlined),
            selectedIcon: Icon(Icons.luggage),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Packing Lists',
          ),
        ],
      ),
    );
  }
}
