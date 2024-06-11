import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:step_coin/splashscreen.dart';
import 'package:step_coin/welcomepage.dart';
import 'MainMenu.dart';
import 'Theme/ThemeProvider.dart';
import 'adManager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  AdManager().updateRequestConfiguration();
  AdManager().initialize();
  print('Firebase and AdManager initialized successfully');

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String theme = prefs.getString('theme') ?? 'light';
  ThemeData initialTheme = theme == 'dark' ? darkTheme : lightTheme;

  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(initialTheme),
      child: MyApp(),
    ),
  );
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int steps = prefs.getInt('steps') ?? 0;
    int lastStepCount = prefs.getInt('lastStepCount') ?? 0;

    // Simulate step calculation
    steps += 10; // Replace this with actual step calculation logic
    prefs.setInt('steps', steps);

    // Check if it's a new day
    DateTime now = DateTime.now();
    DateTime lastResetDate = DateTime.parse(prefs.getString('lastResetDate') ?? now.toIso8601String());

    if (now.difference(lastResetDate).inDays >= 1) {
      // Save steps and reset daily steps
      String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
      List<dynamic> dailySteps = (await userDoc.get()).data()?['DailySteps'] ?? [];

      dailySteps.add({
        'date': lastResetDate.toIso8601String(),
        'steps': steps,
        'coins': (steps / 3).toInt(),
      });

      await userDoc.update({
        'DailySteps': dailySteps,
        'CurrentDaySteps': 0,
        'LastResetDate': now,
        'Coins': FieldValue.increment((steps / 3).toInt()),
        'CoinsEarnedToday': FieldValue.increment((steps / 3).toInt()),
      });

      prefs.setInt('coinValue', (prefs.getInt('coinValue') ?? 0) + (steps / 3).toInt());
      prefs.setInt('steps', 0);
      prefs.setString('lastResetDate', now.toIso8601String());
    }

    return Future.value(true);
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Step Coin',
      theme: themeProvider.getTheme(),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/welcome': (context) => WelcomePage(),
        '/mainmenu': (context) => MainMenu(),
      },
    );
  }
}
