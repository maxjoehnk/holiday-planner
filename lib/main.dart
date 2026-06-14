import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:holiday_planner/l10n/app_localizations.dart';
import 'package:holiday_planner/services/data_change_bus.dart';
import 'package:holiday_planner/src/rust/frb_generated.dart';
import 'package:holiday_planner/src/rust/api.dart';
import 'package:holiday_planner/views/home.dart';
import 'package:intl/intl_standalone.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';
import 'package:holiday_planner/views/share_receiver/komoot_route_import_flow.dart';
import 'package:holiday_planner/views/share_receiver/paste_komoot_url_dialog.dart';
import 'package:holiday_planner/views/share_receiver/shared_train_handler.dart';
import 'package:holiday_planner/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SettingsModel settings = SettingsModel();
  await Future.wait([
    openDatabase(),
    findSystemLocale(),
    settings.loadThemeMode(),
  ]);

  DataChangeBus.instance.start();

  runApp(HolidayPlannerApp(settings));
}

Future<void> openDatabase() async {
  await RustLib.init();
  var directory = await getApplicationDocumentsDirectory();
  await connectDb(path: directory.path);
}

class HolidayPlannerApp extends StatefulWidget {
  final SettingsModel settings;

  const HolidayPlannerApp(this.settings, {super.key});

  @override
  State<HolidayPlannerApp> createState() => _HolidayPlannerAppState();
}

class _HolidayPlannerAppState extends State<HolidayPlannerApp> {
  late StreamSubscription _intentDataStreamSubscription;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initSharingIntent();
  }

  void _initSharingIntent() {
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      _handleSharedMedia(value);
    }, onError: (err) {
      log("getMediaStream error: $err");
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedMedia(value);
      }
    });
  }

  void _handleSharedMedia(List<SharedMediaFile> sharedMedia) {
    for (final media in sharedMedia) {
      if (media.mimeType == 'text/plain' || media.message != null) {
        final textContent = media.message ?? media.path;
        _handleSharedText(textContent);
        break;
      }
    }
  }

  void _handleSharedText(String sharedText) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      return;
    }
    if (komootTourUrlRegex.hasMatch(sharedText)) {
      KomootRouteImportFlow.startFromSharedUrl(context, sharedText);
      return;
    }
    SharedTrainHandler.handleSharedText(context, sharedText);
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    widget.settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.settings,
      child: Consumer<SettingsModel>(
        builder: (context, settings, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('de')
            ],
            themeMode: settings.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.teal,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.teal,
                brightness: Brightness.dark,
              ),
            ),
            home: const HomeView(),
          );
        },
      ),
    );
  }
}
