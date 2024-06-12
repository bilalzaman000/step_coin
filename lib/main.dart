import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:step_coin/splashscreen.dart';
import 'package:step_coin/welcomepage.dart';
import 'MainMenu.dart';
import 'Theme/ThemeProvider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'adManager.dart';




void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      int steps = prefs.getInt('steps') ?? 0;

      // Fetch the dynamic step coin ratio
      DocumentSnapshot rewardRatioSnapshot = await FirebaseFirestore.instance.collection('RewardRatio').doc('StepsDivider').get();
      int stepCoinRatio = rewardRatioSnapshot.get('value') ?? 3; // Default to 3 if the value is not found
      print("object $stepCoinRatio");
      DateTime now = DateTime.now();
      DateTime lastResetDate = DateTime.parse(prefs.getString('lastResetDate') ?? now.toIso8601String());

      if (now.difference(lastResetDate).inDays >= 1) {
        String? uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
          DocumentSnapshot userSnapshot = await userDoc.get();
          List<dynamic> dailySteps = userSnapshot.get('DailySteps') ?? [];

          dailySteps.add({
            'date': lastResetDate.toIso8601String(),
            'steps': steps,
            'coins': (steps / stepCoinRatio).toInt(),
          });

          await userDoc.update({
            'DailySteps': dailySteps,
            'CurrentDaySteps': 0,
            'LastResetDate': now,
            'Coins': FieldValue.increment((steps / stepCoinRatio).toInt()),
          });

          prefs.setInt('coinValue', (prefs.getInt('coinValue') ?? 0) + (steps / stepCoinRatio).toInt());
          prefs.setInt('steps', 0);
          prefs.setString('lastResetDate', now.toIso8601String());
          prefs.setInt('initialSteps', 0);
        }
      }

      return Future.value(true);
    } catch (e) {
      print("Error in callbackDispatcher: $e");
      return Future.value(false);
    }
  });
}



Future<void> requestPermissions() async {
  await [
    Permission.activityRecognition,
    Permission.sensors,
  ].request();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  AdManager().updateRequestConfiguration();
  AdManager().initialize();

  await requestPermissions();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String theme = prefs.getString('theme') ?? 'light';
  ThemeData initialTheme = theme == 'dark' ? darkTheme : lightTheme;

  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  Workmanager().registerPeriodicTask(
    "1",
    "stepCounterTask",
    frequency: Duration(minutes: 15), // Use a reasonable interval
    initialDelay: Duration(seconds: 10),
    constraints: Constraints(
      networkType: NetworkType.not_required,
      requiresBatteryNotLow: true,
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(initialTheme),
      child: MyApp(),
    ),
  );
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
