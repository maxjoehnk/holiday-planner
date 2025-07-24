import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/frb_generated.dart';
import 'package:holiday_planner/src/rust/api.dart';
import 'package:holiday_planner/views/home.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';
import 'package:holiday_planner/views/share_receiver/shared_train_handler.dart';

Future<void> main() async {
  await RustLib.init();
  await connectDb();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription _intentDataStreamSubscription;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initSharingIntent();
  }

  void _initSharingIntent() {
    // Listen to media sharing coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      _handleSharedMedia(value);
    }, onError: (err) {
      print("getMediaStream error: $err");
    });

    // Get the media sharing coming from outside the app while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedMedia(value);
      }
    });
  }

  void _handleSharedMedia(List<SharedMediaFile> sharedMedia) {
    // Extract text from shared media files
    for (final media in sharedMedia) {
      // Check if it's text content
      if (media.mimeType == 'text/plain' || media.message != null) {
        final textContent = media.message ?? media.path;
        _handleSharedText(textContent);
        break; // Process only the first text content
      }
    }
  }

  void _handleSharedText(String sharedText) {
    // Get the current context from the navigator
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
      title: 'Holiday Planner',
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
