import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../adManager.dart';
import 'Home/ReviewScreen.dart';
import 'Home/StepsHistory.dart';
import 'package:pedometer/pedometer.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _coinValue = 0;
  int _steps = 0;
  int _initialSteps = 0;
  late AnimationController _animationController;
  late Animation<double> _stepsAnimation;
  late Animation<double> _coinsAnimation;
  List<Map<String, dynamic>> _widgetsStatus = [];
  DateTime _lastResetDate = DateTime.now();
  late StreamSubscription<StepCount> _stepCountSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _stepsAnimation = Tween<double>(begin: 0, end: _steps.toDouble()).animate(_animationController);
    _coinsAnimation = Tween<double>(begin: 0, end: (_steps / 3).toDouble()).animate(_animationController);
    _fetchCoinValueAndSteps().then((_) => _initPedometer());
    _fetchWidgetStatus();
    _animationController.forward();
    _checkResetSteps();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _stepCountSubscription.cancel();
    super.dispose();
  }

  Future<void> _fetchCoinValueAndSteps() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (snapshot.exists) {
        setState(() {
          _coinValue = prefs.getInt('coinValue') ?? snapshot['Coins'] ?? 0;
          _steps = prefs.getInt('steps') ?? snapshot['CurrentDaySteps'] ?? 0;
          _lastResetDate = (prefs.getString('lastResetDate') != null)
              ? DateTime.parse(prefs.getString('lastResetDate')!)
              : (snapshot['LastResetDate'] as Timestamp).toDate();
          _initialSteps = prefs.getInt('initialSteps') ?? 0;
        });

        _checkResetSteps();
      } else {
        print('Document does not exist');
      }
    }
  }

  Future<void> _fetchWidgetStatus() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('Widgets').get();
      List<Map<String, dynamic>> widgetsStatus = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      setState(() {
        _widgetsStatus = widgetsStatus;
      });
    } catch (e) {
      print('Error fetching widget status: $e');
    }
  }

  void _initPedometer() {
    Pedometer pedometer = Pedometer();
    _stepCountSubscription = Pedometer.stepCountStream.listen(_onStepCount, onError: _onStepCountError);
  }

  void _onStepCount(StepCount event) {
    if (_initialSteps == 0) {
      _initialSteps = event.steps;
      _saveInitialSteps();
    }
    setState(() {
      _steps = event.steps - _initialSteps;
    });
    _saveStepsLocally();
  }

  void _onStepCountError(error) {
    print('Pedometer Error: $error');
  }

  Future<void> _saveInitialSteps() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('initialSteps', _initialSteps);
  }

  Future<void> _saveStepsLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('steps', _steps);
  }

  Future<void> _updateDatabaseWithSteps() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'CurrentDaySteps': _steps,
        'CoinsEarnedToday': (_steps / 3).toInt(),
      });
    }
  }

  void _checkResetSteps() async {
    DateTime now = DateTime.now();
    if (now.difference(_lastResetDate).inDays >= 1) {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
        DocumentSnapshot snapshot = await userDoc.get();
        if (snapshot.exists) {
          List<dynamic> dailySteps = snapshot['DailySteps'] ?? [];
          dailySteps.add({
            'date': _lastResetDate.toIso8601String(),
            'steps': _steps,
            'coins': (_steps / 3).toInt(),
          });
          await userDoc.update({
            'DailySteps': dailySteps,
            'CurrentDaySteps': 0,
            'LastResetDate': now,
            'Coins': FieldValue.increment((_steps / 3).toInt()),
            'CoinsEarnedToday': FieldValue.increment((_steps / 3).toInt()),
          });

          setState(() {
            _steps = 0;
            _lastResetDate = now;
            _coinValue += (_steps / 3).toInt();
            _initialSteps = 0; // Reset initial steps
          });

          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setInt('coinValue', _coinValue);
          prefs.setInt('steps', _steps);
          prefs.setString('lastResetDate', _lastResetDate.toIso8601String());
          prefs.setInt('initialSteps', _initialSteps);
        }
      }
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
            GestureDetector(
              onTap: () async {
                await _updateDatabaseWithSteps();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StepsHistory()),
                );
              },
              child: Container(
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
            ),
            SizedBox(height: 20),
            Text('More Ways to Earn Coins', style: TextStyle(color: theme.colorScheme.onBackground, fontSize: 18)),
            SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: _widgetsStatus
                    .where((widget) => widget['enabled'] == true)
                    .map((widget) {
                  switch (widget['name']) {
                    case 'Watch an ad':
                      return _buildListItem('Watch an ad', 50, 'assets/Home/Video.png', context, null);
                    case 'Give a Review':
                      return _buildListItem('Give a Review', 500, 'assets/Home/Star.png', context, ReviewScreen());
                    case 'Submit A Survey':
                      return _buildListItem('Submit A Survey', 77, 'assets/Home/Pen.png', context, null, true);
                    case 'Play A Game':
                      return _buildListItem('Play A Game', 77, 'assets/Home/Cube.png', context, null, true);
                    default:
                      return Container();
                  }
                }).toList(),
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
        onTap: () async {
          if (title == 'Watch an ad') {
            AdManager().showRewardedAd(context);
          } else if (showComingSoon) {
            _showComingSoonDialog();
          } else if (nextScreen != null) {
            await _updateDatabaseWithSteps();
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
