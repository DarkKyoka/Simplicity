import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  final startAsTray = const String.fromEnvironment('FLUTTER_ARGS').contains('--tray') ||
      (const bool.fromEnvironment('dart.vm.product') ? false : false);
  // Check process args for --tray
  final args = List<String>.from(const String.fromEnvironment('FLUTTER_ARGS', defaultValue: '').split(' '));
  runApp(SimplicityApp(startAsTray: args.contains('--tray')));
}

class SimplicityApp extends StatelessWidget {
  final bool startAsTray;
  const SimplicityApp({super.key, this.startAsTray = false});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Simplicity',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF534AB7), brightness: Brightness.dark),
      useMaterial3: true,
    ),
    home: HomePage(startMinimized: startAsTray),
  );
}