import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pedometer/pedometer.dart';
import '../adManager.dart';
import 'Home/ReviewScreen.dart';
import 'Home/StepsHistory.dart';
import 'package:sensors_plus/sensors_plus.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _coinValue = 0;
  int _TcoinValue = 0;
  int _steps = 0;
  int _initialSteps = 0;
  late AnimationController _animationController;
  late Animation<double> _stepsAnimation;
  late Animation<double> _coinsAnimation;
  List<Map<String, dynamic>> _widgetsStatus = [];
  DateTime _lastResetDate = DateTime.now();
  late StreamSubscription<StepCount> _stepCountSubscription;
  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  bool _isDriving = false;
  int _stepsDivider = 1;
  int _adReward = 0;
  int _reviewReward = 0;
  int _gameReward = 0;
  int _surveyReward = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _stepsAnimation = Tween<double>(begin: 0, end: _steps.toDouble()).animate(_animationController);
    _coinsAnimation = Tween<double>(begin: 0, end: (_steps / _stepsDivider).toDouble()).animate(_animationController);
    _fetchCoinValueAndSteps().then((_) {
      _initPedometer();
      _initAccelerometer();
    });
    _fetchWidgetStatus();
    _fetchRewardRatios();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _stepCountSubscription.cancel();
    _accelerometerSubscription.cancel();
    super.dispose();
  }

  Future<void> _fetchRewardRatios() async {
    try {
      DocumentSnapshot stepsDividerSnapshot = await FirebaseFirestore.instance.collection('RewardRatio').doc('StepsDivider').get();
      DocumentSnapshot adSnapshot = await FirebaseFirestore.instance.collection('RewardRatio').doc('Ad').get();
      DocumentSnapshot reviewSnapshot = await FirebaseFirestore.instance.collection('RewardRatio').doc('Review').get();
      DocumentSnapshot gameSnapshot = await FirebaseFirestore.instance.collection('RewardRatio').doc('Game').get();
      DocumentSnapshot surveySnapshot = await FirebaseFirestore.instance.collection('RewardRatio').doc('Survey').get();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _stepsDivider = stepsDividerSnapshot['value'];
          _adReward = adSnapshot['value'];
          _reviewReward = reviewSnapshot['value'];
          _gameReward = gameSnapshot['value'];
          _surveyReward = surveySnapshot['value'];
        });
        prefs.setInt('stepsDivider', _stepsDivider); // Save stepsDivider to SharedPreferences
      }
    } catch (e) {
      print('Error fetching reward ratios: $e');
    }
  }

  Future<void> _fetchCoinValueAndSteps() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (snapshot.exists) {
        if (mounted) {
          setState(() {
            _TcoinValue = snapshot['Coins'] ?? 0;
            _steps = prefs.getInt('steps') ?? snapshot['CurrentDaySteps'] ?? 0;
            _lastResetDate = (prefs.getString('lastResetDate') != null)
                ? DateTime.parse(prefs.getString('lastResetDate')!)
                : (snapshot['LastResetDate'] as Timestamp).toDate();
            _initialSteps = prefs.getInt('initialSteps') ?? 0;
          });
        }
        await _updateDatabaseWithSteps();
      } else {
        print('Document does not exist');
      }
    }
  }

  Future<void> _fetchWidgetStatus() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('Widgets').get();
      List<Map<String, dynamic>> widgetsStatus = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      if (mounted) {
        setState(() {
          _widgetsStatus = widgetsStatus;
        });
      }
    } catch (e) {
      print('Error fetching widget status: $e');
    }
  }

  void _initPedometer() {
    Pedometer pedometer = Pedometer();
    _stepCountSubscription = Pedometer.stepCountStream.listen(_onStepCount, onError: _onStepCountError);
  }

  void _initAccelerometer() {
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      double acceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (acceleration > 15) {
        setState(() {
          _isDriving = true;
        });
      } else {
        setState(() {
          _isDriving = false;
        });
      }
    });
  }

  void _onStepCount(StepCount event) {
    if (!_isDriving) {
      if (_initialSteps == 0) {
        _initialSteps = event.steps;
        _saveInitialSteps();
      }
      setState(() {
        _steps = event.steps - _initialSteps;
      });
      _saveStepsLocally();
      _updateDatabaseWithSteps();
    }
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
      final snapshot = await userDoc.get();
      if (snapshot.exists) {
        final now = DateTime.now();
        final currentSteps = _steps;
        int storedSteps = prefs.getInt('steps') ?? 0;

        if (_lastResetDate.isBefore(DateTime(now.year, now.month, now.day))) {
          int stepsDivider = prefs.getInt('stepsDivider') ?? 1; // Default to 1 if not set
          int coinsEarned = (storedSteps / stepsDivider).toInt();
          List<dynamic> dailySteps = snapshot['DailySteps'] ?? [];
          dailySteps.add({
            'date': _lastResetDate.toIso8601String(),
            'steps': storedSteps,
            'coins': coinsEarned,
          });
          await userDoc.update({
            'DailySteps': dailySteps,
            'CurrentDaySteps': 0,
            'LastResetDate': now,
            'Coins': FieldValue.increment(coinsEarned),
          });
          prefs.setInt('coinValue', (prefs.getInt('coinValue') ?? 0) + coinsEarned);
          prefs.setInt('steps', 0);
          prefs.setString('lastResetDate', now.toIso8601String());
          prefs.setInt('initialSteps', 0);
          setState(() {
            _steps = 0;
          });
        } else {
          await userDoc.update({
            'CurrentDaySteps': currentSteps,
          });
        }

        List<dynamic> dailySteps = snapshot['DailySteps'] ?? [];
        bool todayEntryExists = false;
        for (var entry in dailySteps) {
          DateTime entryDate;
          if (entry['date'] is Timestamp) {
            entryDate = (entry['date'] as Timestamp).toDate();
          } else if (entry['date'] is String) {
            entryDate = DateTime.parse(entry['date']);
          } else {
            continue;
          }

          if (entryDate.day == now.day &&
              entryDate.month == now.month &&
              entryDate.year == now.year) {
            entry['steps'] = currentSteps;
            todayEntryExists = true;
            break;
          }
        }

        if (!todayEntryExists) {
          dailySteps.add({
            'date': now.toIso8601String(),
            'steps': currentSteps,
          });
        }

        await userDoc.update({
          'DailySteps': dailySteps,
          'CurrentDaySteps': currentSteps,
        });

        if (mounted) {
          setState(() {
            _coinValue = (currentSteps / _stepsDivider).toInt();
          });
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
    Color containerColor = theme.brightness == Brightness.light ? Color(0xFFFAFAFB) : theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: appBarColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('   StepCoins', style: TextStyle(color: theme.brightness == Brightness.light ? Colors.black : Colors.white)),
            Row(
              children: [
                Image.asset('assets/Coin.png', height: 24),
                SizedBox(width: 8),
                Text('$_TcoinValue', style: TextStyle(fontSize: 24, color: theme.brightness == Brightness.light ? Colors.black : Colors.white)),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StepsHistory()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.all(2.0),
                height: MediaQuery.of(context).size.height * 0.25,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Today Steps', style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface)),
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
                        Text('${(_steps / _stepsDivider).toInt()}', style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface)),
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
                      return _buildListItem('Watch an ad', _adReward, 'assets/Home/Video.png', context, null);
                    case 'Give a Review':
                      return _buildListItem('Give a Review', _reviewReward, 'assets/Home/Star.png', context, ReviewScreen());
                    case 'Submit A Survey':
                      return _buildListItem('Submit A Survey', _surveyReward, 'assets/Home/Pen.png', context, null, true);
                    case 'Play A Game':
                      return _buildListItem('Play A Game', _gameReward, 'assets/Home/Cube.png', context, null, true);
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
    final theme = Theme.of(context);
    Color tileColor = theme.brightness == Brightness.light ? Color(0xFFFAFAFB) : theme.colorScheme.surface;

    return Card(
      color: tileColor,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        onTap: () async {
          if (title == 'Watch an ad') {
            AdManager().showRewardedAd(context, _adReward, () async {
              setState(() {
                _TcoinValue += coins;
              });
            });
          } else if (showComingSoon) {
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
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/Coin.png', height: 24),
            SizedBox(width: 8),
            Text(
              '$coins',
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}
