import 'package:flutter/material.dart';
import 'package:holiday_planner/settings.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:holiday_planner/l10n/app_localizations.dart';
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
            title: Text(AppLocalizations.of(context)!.settingsTitle),
            centerTitle: true,
          ),
          body: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  AppLocalizations.of(context)!.appearanceSection,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              RadioListTile<ThemeMode>(
                title: Text(AppLocalizations.of(context)!.useSystemTheme),
                value: ThemeMode.system,
                groupValue: currentMode,
                onChanged: (val) {
                  if (val != null) {
                    settings.updateThemeMode(val);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(AppLocalizations.of(context)!.themeLight),
                value: ThemeMode.light,
                groupValue: currentMode,
                onChanged: (val) {
                  if (val != null) {
                    settings.updateThemeMode(val);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(AppLocalizations.of(context)!.themeDark),
                value: ThemeMode.dark,
                groupValue: currentMode,
                onChanged: (val) {
                  if (val != null) {
                    settings.updateThemeMode(val);
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  AppLocalizations.of(context)!.languageSection,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              RadioListTile<Locale?>(
                title: Text(AppLocalizations.of(context)!.useSystemLanguage),
                value: null,
                groupValue: settings.locale,
                onChanged: (val) => settings.updateLocale(val),
              ),
              RadioListTile<Locale?>(
                title: Text(AppLocalizations.of(context)!.languageEnglish),
                value: const Locale('en'),
                groupValue: settings.locale,
                onChanged: (val) => settings.updateLocale(val),
              ),
              RadioListTile<Locale?>(
                title: Text(AppLocalizations.of(context)!.languageGerman),
                value: const Locale('de'),
                groupValue: settings.locale,
                onChanged: (val) => settings.updateLocale(val),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  AppLocalizations.of(context)!.aboutSection,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      final version = asyncSnapshot.requireData.version;
                      return Text(
                          AppLocalizations.of(context)!.aboutAppWithVersion(version),
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
