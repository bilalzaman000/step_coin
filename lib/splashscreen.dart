import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:step_coin/welcomepage.dart';
import 'dart:async';
import 'MainMenu.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _requestActivityRecognitionPermission();
    _navigateBasedOnAuthStatus();
  }

  Future<void> _requestActivityRecognitionPermission() async {
    var status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      print('Activity recognition permission granted.');
    } else {
      print('Activity recognition permission not granted.');
      await _showPermissionDialog();
    }
  }

  Future<void> _showPermissionDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Activity Recognition Permission Required'),
          content: Text(
              'This app requires activity recognition permission to function correctly. Please enable it in the app settings.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateBasedOnAuthStatus() {
    Timer(Duration(seconds: 3), () {
      // Check if the user is authenticated
      if (FirebaseAuth.instance.currentUser != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainMenu()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WelcomePage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set the background to black
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Colors.yellow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 10,
                    child: Image.asset(
                      'assets/SplashScreen/TopLine.png',
                      width: 200,
                      height: 200,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/SplashScreen/BlackRectangle.png',
                              width: 30,
                              height: 50,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'StepCoin',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Image.asset(
                          'assets/SplashScreen/BottomLine.png',
                          width: MediaQuery.of(context).size.width * 0.9,
                          height: 200,
                          fit: BoxFit.fill,
                        ),
                        Image.asset(
                          'assets/SplashScreen/Coin.png',
                          width: 100,
                          height: 100,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/SplashScreen/BottomImage.png',
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.15,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
