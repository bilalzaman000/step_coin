import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pedometer/pedometer.dart';
import '../adManager.dart';
import 'Home/ReviewScreen.dart';
import 'Home/StepsHistory.dart';

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
  int _stepsDivider = 3;
  int _adReward = 50;
  int _reviewReward = 500;
  int _gameReward = 77;
  int _surveyReward = 77;

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
      _checkResetSteps();
      _initPedometer();
    });
    _fetchWidgetStatus();
    _fetchRewardRatios();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _stepCountSubscription.cancel();
    super.dispose();
  }

  Future<void> _fetchRewardRatios() async {
    try {
      DocumentSnapshot stepsDividerSnapshot = await FirebaseFirestore.instance.collection('RewardRatio').doc('StepsDivider').get();
      DocumentSnapshot adSnapshot = await FirebaseFirestore.instance.collection('RewardRatio').doc('Ad').get();
      DocumentSnapshot reviewSnapshot = await FirebaseFirestore.instance.collection('RewardRatio').doc('Review').get();
      DocumentSnapshot gameSnapshot = await FirebaseFirestore.instance.collection('RewardRatio').doc('Game').get();
      DocumentSnapshot surveySnapshot = await FirebaseFirestore.instance.collection('RewardRatio').doc('Survey').get();

      setState(() {
        _stepsDivider = stepsDividerSnapshot['value'];
        _adReward = adSnapshot['value'];
        _reviewReward = reviewSnapshot['value'];
        _gameReward = gameSnapshot['value'];
        _surveyReward = surveySnapshot['value'];
      });
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
        setState(() {
          _TcoinValue = snapshot['Coins'] ?? 0;
          print("$_TcoinValue");
          _steps = prefs.getInt('steps') ?? snapshot['CurrentDaySteps'] ?? 0;
          _lastResetDate = (prefs.getString('lastResetDate') != null)
              ? DateTime.parse(prefs.getString('lastResetDate')!)
              : (snapshot['LastResetDate'] as Timestamp).toDate();
          _initialSteps = prefs.getInt('initialSteps') ?? 0;
        });
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
    _updateDatabaseWithSteps();
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
      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
      final snapshot = await userDoc.get();
      if (snapshot.exists) {
        final now = DateTime.now();
        final currentSteps = _steps;
        final currentCoins = (currentSteps / _stepsDivider).toInt();

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
            entry['coins'] = currentCoins;
            todayEntryExists = true;
            break;
          }
        }

        if (!todayEntryExists) {
          dailySteps.add({
            'date': now,
            'steps': currentSteps,
            'coins': currentCoins,
          });
        }

        await userDoc.update({
          'DailySteps': dailySteps,
          'CurrentDaySteps': currentSteps,
          'CoinsEarnedToday': currentCoins,
        });

        setState(() {
          _coinValue = currentCoins;
        });
      }
    }
  }

  Future<void> resetSteps() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      final DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
      final DocumentSnapshot snapshot = await userDoc.get();

      if (snapshot.exists) {
        final int currentSteps = prefs.getInt('steps') ?? 0;
        final int coinsEarnedToday = (currentSteps / _stepsDivider).toInt();
        final DateTime now = DateTime.now();

        List<dynamic> dailySteps = snapshot['DailySteps'] ?? [];
        dailySteps.add({
          'date': now.toIso8601String(),
          'steps': currentSteps,
          'coins': coinsEarnedToday,
        });

        await userDoc.update({
          'DailySteps': dailySteps,
          'CurrentDaySteps': 0,
          'LastResetDate': now,
          'Coins': FieldValue.increment(coinsEarnedToday),
          'CoinsEarnedToday': 0,
        });

        prefs.setInt('coinValue', (prefs.getInt('coinValue') ?? 0) + coinsEarnedToday);
        prefs.setInt('steps', 0);
        prefs.setString('lastResetDate', now.toIso8601String());
        prefs.setInt('initialSteps', 0);

        setState(() {
          _coinValue = prefs.getInt('coinValue')!;
          _steps = 0;
          _initialSteps = 0;
        });
      }
    }
  }

  void _checkResetSteps() {
    final DateTime now = DateTime.now();
    if (now.difference(_lastResetDate).inDays >= 1) {
      resetSteps();
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
                  color: theme.colorScheme.surface,
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
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        onTap: () async {
          if (title == 'Watch an ad') {
            AdManager().showRewardedAd(context, () async {
              // Update coins instantly after the ad is completed
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
