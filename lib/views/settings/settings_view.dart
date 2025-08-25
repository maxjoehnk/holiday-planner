import 'package:flutter/material.dart';
import 'package:holiday_planner/settings.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({
    super.key,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final Future<PackageInfo> _packageInfoFuture = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsModel>(
      builder: (context, settings, _) {
        final currentMode = settings.themeMode;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            centerTitle: true,
          ),
          body: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Appearance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Use system theme'),
                value: ThemeMode.system,
                groupValue: currentMode,
                onChanged: (val) {
                  if (val != null) {
                    settings.updateThemeMode(val);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: currentMode,
                onChanged: (val) {
                  if (val != null) {
                    settings.updateThemeMode(val);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: currentMode,
                onChanged: (val) {
                  if (val != null) {
                    settings.updateThemeMode(val);
                  }
                },
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'About',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: FutureBuilder(
                    future: _packageInfoFuture,
                    builder: (context, asyncSnapshot) {
                      if (!asyncSnapshot.hasData) {
                        return Container();
                      }
                      return Text(
                          'Holiday Planner App ${asyncSnapshot.requireData.version}',
                          style: Theme.of(context).textTheme.bodyMedium);
                    }),
              ),
            ],
          ),
        );
      },
    );
  }
}
