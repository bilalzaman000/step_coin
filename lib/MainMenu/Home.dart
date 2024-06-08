import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health/health.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../Theme/ThemeProvider.dart';
import 'Home/ReviewScreen.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _coinValue = 0;
  int _steps = 6000;
  HealthFactory health = HealthFactory();
  late AnimationController _animationController;
  late Animation<double> _stepsAnimation;
  late Animation<double> _coinsAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    // Initialize animations with default values
    _stepsAnimation = Tween<double>(begin: 0, end: _steps.toDouble()).animate(_animationController);
    _coinsAnimation = Tween<double>(begin: 0, end: (_steps / 3).toDouble()).animate(_animationController);

    _fetchCoinValue();
    _fetchSteps();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCoinValue() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (snapshot.exists) {
        setState(() {
          _coinValue = snapshot['Coins'] ?? 0;
        });
      } else {
        print('Document does not exist');
      }
    }
  }

  Future<void> _fetchSteps() async {
    try {
      bool isAuthorized = await health.requestAuthorization([HealthDataType.STEPS]);
      if (isAuthorized) {
        print('Authorization granted');
        List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
          DateTime.now().subtract(Duration(days: 1)),
          DateTime.now(),
          [HealthDataType.STEPS],
        );
        int totalSteps = healthData.fold(0, (sum, data) => sum + (data.value as int));
        print('Total steps fetched: $totalSteps');
        setState(() {
          _steps = totalSteps;
          _stepsAnimation = Tween<double>(begin: 0, end: _steps.toDouble()).animate(_animationController);
          _coinsAnimation = Tween<double>(begin: 0, end: (_steps / 3).toDouble()).animate(_animationController);
          _animationController.forward(from: 0);
        });
      } else {
        print('Authorization not granted');
      }
    } catch (e) {
      print('Error fetching steps: $e');
    }
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text('Please Wait...', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: Text('Coming soon', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          actions: [
            TextButton(
              child: Text('OK', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color appBarColor = theme.brightness == Brightness.light ? Colors.white : Colors.black;
    return Scaffold(
      backgroundColor: appBarColor,
       appBar: AppBar(
    backgroundColor: theme.brightness == Brightness.light ? Colors.white : Colors.black,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('   StepCoins', style: TextStyle(color: theme.brightness == Brightness.light ? Colors.black : Colors.white)),
          Row(
            children: [
              Image.asset('assets/Coin.png', height: 24),
              SizedBox(width: 8),
              Text('$_coinValue', style: TextStyle(fontSize: 24, color: theme.brightness == Brightness.light ? Colors.black : Colors.white)),
              SizedBox(width: 8),
            ],
          ),
        ],
      ),
    ),

    body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.all(2.0),
              height: MediaQuery.of(context).size.height * 0.25,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Total Steps', style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface)),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/Home/Steps.png', height: 50),
                      SizedBox(width: 8),
                      Text('${_steps.toString()}', style: TextStyle(fontSize: 50, color: theme.colorScheme.onSurface)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/Coin.png', height: 24),
                      SizedBox(width: 8),
                      Text('${(_steps / 3).toInt()}', style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface)),
                      SizedBox(width: 6),
                      Text('Earned Today', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text('More Ways to Earn Coins', style: TextStyle(color: theme.colorScheme.onBackground, fontSize: 18)),
            SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  _buildListItem('Watch an ad', 77, 'assets/Home/Video.png', context, WatchAdScreen()),
                  _buildListItem('Give a Review', 500, 'assets/Home/Star.png', context, ReviewScreen()),
                  _buildListItem('Submit A Survey', 77, 'assets/Home/Pen.png', context, null, true),
                  _buildListItem('Play A Game', 77, 'assets/Home/Cube.png', context, null, true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(String title, int coins, String imagePath, BuildContext context, Widget? nextScreen, [bool showComingSoon = false]) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        onTap: () {
          if (showComingSoon) {
            _showComingSoonDialog();
          } else if (nextScreen != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => nextScreen),
            );
          }
        },
        leading: CircleAvatar(
          backgroundImage: AssetImage(imagePath),
          radius: 24,
        ),
        title: Text(
          title,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/Coin.png', height: 24),
            SizedBox(width: 8),
            Text(
              '$coins',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class WatchAdScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Watch an Ad'),
      ),
      body: Center(
        child: Text('Watch an Ad screen content.'),
      ),
    );
  }
}

class SubmitSurveyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Submit a Survey'),
      ),
      body: Center(
        child: Text('Submit a Survey screen content.'),
      ),
    );
  }
}

class PlayGameScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Play a Game'),
      ),
      body: Center(
        child: Text('Play a Game screen content.'),
      ),
    );
  }
}
