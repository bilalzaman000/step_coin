import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:step_coin/splashscreen.dart';
import 'package:step_coin/welcomepage.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  print('Firebase connected successfully');
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
