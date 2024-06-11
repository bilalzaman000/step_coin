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
    steps += 10; // Simulate step increment
    prefs.setInt('steps', steps);
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
