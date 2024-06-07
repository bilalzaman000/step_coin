import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health/health.dart';
import 'dart:math';

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
          backgroundColor: Colors.black,
          title: Text('Please Wait...', style: TextStyle(color: Colors.white)),
          content: Text('Coming soon', style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              child: Text('OK', style: TextStyle(color: Colors.white)),
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'StepCoins',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                Row(
                  children: [
                    Image.asset('assets/Coin.png', height: 24),
                    SizedBox(width: 8),
                    Text(
                      '$_coinValue',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            // Meter
            Center(
              child: CustomPaint(
                size: Size(200, 200), // Adjust the size
                painter: StepMeterPainter(_stepsAnimation.value),
                child: Container(
                  width: 200,
                  height: 200,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Steps: ${_stepsAnimation.value.toInt()}',
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                            Text(
                              'Coins: ${_coinsAnimation.value.toInt()}',
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            // List view
            Expanded(
              child: ListView(
                children: [
                  _buildListItem('Watch an ad', 77, Icons.video_library, context, WatchAdScreen()),
                  _buildListItem('Give a Review', 500, Icons.star, context, ReviewScreen()),
                  _buildListItem('Submit A Survey', 77, Icons.edit, context, null, true),
                  _buildListItem('Play A Game', 77, Icons.videogame_asset, context, null, true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(String title, int coins, IconData icon, BuildContext context, Widget? nextScreen, [bool showComingSoon = false]) {
    return Card(
      color: Colors.grey[900],
      margin: EdgeInsets.symmetric(vertical: 8.0), // Adjust margin for better spacing
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
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: TextStyle(color: Colors.white),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/Coin.png', height: 24),
            SizedBox(width: 8),
            Text(
              '$coins',
              style: TextStyle(color: Colors.white, fontSize: 24), // Adjust font size
            ),
          ],
        ),
      ),
    );
  }
}

class StepMeterPainter extends CustomPainter {
  final double steps;
  StepMeterPainter(this.steps);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;

    double totalSteps = 6000;
    double anglePerStep = 2 * pi / totalSteps;

    // Draw the full grey circle
    paint.color = Colors.grey;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width / 2),
      0,
      2 * pi,
      false,
      paint,
    );

    // Draw the arc in sections
    double startAngle = -pi / 2;

    // Orange section
    paint.color = Colors.yellow[500]!;
    double orangeSweepAngle = anglePerStep * min(steps, 2000);
    if (orangeSweepAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width / 2),
        startAngle,
        orangeSweepAngle,
        false,
        paint,
      );
    }

    // Blue section
    double blueSweepAngle = 0;
    if (steps > 2000) {
      paint.color = Colors.yellowAccent;
      double blueStartAngle = startAngle + orangeSweepAngle;
      blueSweepAngle = anglePerStep * min(steps - 2000, 2000);
      if (blueSweepAngle > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width / 2),
          blueStartAngle,
          blueSweepAngle,
          false,
          paint,
        );
      }
    }

    // Yellow section
    if (steps > 4000) {
      paint.color = Colors.yellow;
      double yellowStartAngle = startAngle + orangeSweepAngle + blueSweepAngle;
      double yellowSweepAngle = anglePerStep * min(steps - 4000, 2000);
      if (yellowSweepAngle > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width / 2),
          yellowStartAngle,
          yellowSweepAngle,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
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
