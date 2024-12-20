import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartcoaster/provider/provider.dart';
import 'package:smartcoaster/screens/scanningScreen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Coaster',
      theme: ThemeData.dark(),
      home: ScanningScreen(),
    );
  }
}
