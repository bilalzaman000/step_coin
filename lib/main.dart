import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:step_coin/splashscreen.dart';
import 'package:step_coin/welcomepage.dart';
import 'Theme/ThemeProvider.dart';
import 'adManager.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler package

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  AdManager().updateRequestConfiguration(); // Update request configuration with test device IDs
  AdManager().initialize(); // Initialize AdManager
  print('Firebase and AdManager initialized successfully');

  // Request permission
  var status = await Permission.activityRecognition.request();
  if (status.isGranted) {
    print('Activity recognition permission granted.');
  } else {
    print('Activity recognition permission not granted.');
    // Handle accordingly, e.g., show a dialog to the user
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String theme = prefs.getString('theme') ?? 'light';
  ThemeData initialTheme = theme == 'dark' ? darkTheme : lightTheme;

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
      },
    );
  }
}
