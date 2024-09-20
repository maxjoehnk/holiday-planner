import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/frb_generated.dart';
import 'package:holiday_planner/src/rust/api.dart';
import 'package:holiday_planner/views/home.dart';

Future<void> main() async {
  await RustLib.init();
  await connectDb();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
