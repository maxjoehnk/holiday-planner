import 'package:flutter/material.dart';
import 'package:holiday_planner/settings.dart';
import 'package:provider/provider.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({
    super.key,
  });

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
            ],
          ),
        );
      },
    );
  }
}
