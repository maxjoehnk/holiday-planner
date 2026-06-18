import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:holiday_planner/services/auth_service.dart';
import 'package:holiday_planner/src/rust/api.dart';
import 'package:holiday_planner/views/auth/account_view.dart';
import 'package:holiday_planner/views/auth/sign_in_view.dart';
import 'package:holiday_planner/views/settings/settings_view.dart';
import 'package:holiday_planner/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        title: Text(AppLocalizations.of(context)!.appTitle),
        centerTitle: true,
        elevation: 0,
        actions: [
          StreamBuilder<User?>(
            stream: AuthService.instance.changes,
            initialData: AuthService.instance.currentUser,
            builder: (context, snapshot) {
              final signedIn = snapshot.data != null;
              return IconButton(
                tooltip: signedIn ? 'Account' : 'Sign in',
                icon: Icon(signedIn ? Icons.account_circle : Icons.account_circle_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => signedIn ? const AccountView() : const SignInView(),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.homeSettingsTooltip,
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
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.luggage_outlined),
            selectedIcon: const Icon(Icons.luggage),
            label: AppLocalizations.of(context)!.navTrips,
          ),
          NavigationDestination(
            icon: const Icon(Icons.checklist_outlined),
            selectedIcon: const Icon(Icons.checklist),
            label: AppLocalizations.of(context)!.navPackingLists,
          ),
        ],
      ),
    );
  }
}
