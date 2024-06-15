import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:step_coin/splashscreen.dart';
import 'package:step_coin/welcomepage.dart';
import 'MainMenu.dart';
import 'StepService.dart';
import 'Theme/ThemeProvider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'adManager.dart';


void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('\x1B[31mExecuting midnight task\x1B[0m'); // Added logging
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();
      SharedPreferences prefs = await SharedPreferences.getInstance();

      int stepsDivider = prefs.getInt('stepsDivider') ?? 1; // Default to 1 if not set
      await StepService.resetSteps(stepsDivider); // Call the resetSteps function with the stepsDivider

      scheduleMidnightTask(); // Reschedule the task for the next midnight
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

void scheduleMidnightTask() {
  DateTime now = DateTime.now();
  DateTime midnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
  String redText = '\x1B[31mScheduling task for midnight: $midnight\x1B[0m';
  print(redText);
  Duration initialDelay = midnight.difference(now);
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  Workmanager().registerOneOffTask(
    "1",
    "stepCounterTask",
    initialDelay: initialDelay,
    constraints: Constraints(
      networkType: NetworkType.not_required,
      requiresBatteryNotLow: true,
    ),
  );
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

  scheduleMidnightTask();

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
