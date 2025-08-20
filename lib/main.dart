import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/frb_generated.dart';
import 'package:holiday_planner/src/rust/api.dart';
import 'package:holiday_planner/views/home.dart';
import 'package:intl/intl_standalone.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';
import 'package:holiday_planner/views/share_receiver/shared_train_handler.dart';

Future<void> main() async {
  await RustLib.init();
  WidgetsFlutterBinding.ensureInitialized();
  var directory = await getApplicationDocumentsDirectory();
  await connectDb(path: directory.path);
  await findSystemLocale();

  runApp(const HolidayPlannerApp());
}

class HolidayPlannerApp extends StatefulWidget {
  const HolidayPlannerApp({super.key});

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
    if (context != null) {
      SharedTrainHandler.handleSharedText(context, sharedText);
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Trippy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
        ),
        useMaterial3: true,
      ),
      home: const HomeView(),
    );
  }
}
