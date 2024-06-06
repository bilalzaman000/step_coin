import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:step_coin/splashscreen.dart';
import 'package:step_coin/welcomepage.dart';

import 'adManager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  AdManager().updateRequestConfiguration(); // Update request configuration with test device IDs
  AdManager().initialize(); // Initialize AdManager
  print('Firebase and AdManager initialized successfully');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Step Coin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/welcome': (context) => WelcomePage(),
      },
    );
  }
}
