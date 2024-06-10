import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:background_fetch/background_fetch.dart';
import '../Widgets/StepsCounter.dart';
import '../adManager.dart';
import 'Home/ReviewScreen.dart';
import 'Home/StepsHistory.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _coinValue = 0;
  int _steps = 0;
  late AnimationController _animationController;
  late Animation<double> _stepsAnimation;
  late Animation<double> _coinsAnimation;
  List<Map<String, dynamic>> _widgetsStatus = [];
  DateTime _lastResetDate = DateTime.now();
  int _lastSteps = 0;

  final StepCounter _stepCounter = StepCounter(); // Initialize StepCounter

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _stepsAnimation = Tween<double>(begin: 0, end: _steps.toDouble()).animate(_animationController);
    _coinsAnimation = Tween<double>(begin: 0, end: (_steps / 3).toDouble()).animate(_animationController);
    _fetchCoinValue();
    _initPedometer();
    _fetchWidgetStatus();
    _animationController.forward();

    // Initialize Background Fetch
    BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        startOnBoot: true,
      ),
      _onBackgroundFetch,
    ).then((int status) {
      print('Background Fetch configured: $status');
    }).catchError((e) {
      print('Error configuring Background Fetch: $e');
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCoinValue() async {
    final prefs = await SharedPreferences.getInstance();
    int localCoinValue = prefs.getInt('coinValue') ?? 0;

    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (snapshot.exists) {
        setState(() {
          _coinValue = snapshot['Coins'] ?? 0;
          _lastResetDate = (snapshot['LastResetDate'] as Timestamp).toDate();
          _steps = snapshot['CurrentDaySteps'] ?? 0;
        });
        _checkResetSteps();
      } else {
        print('Document does not exist');
      }
    }

    setState(() {
      _coinValue = localCoinValue;
    });
  }

  Future<void> _updateCoinValue(int newValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coinValue', newValue);
    setState(() {
      _coinValue = newValue;
    });
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
    accelerometerEvents.listen((AccelerometerEvent event) {
      _stepCounter.onAccelerometerEvent(event.x, event.y, event.z);
      setState(() {
        _steps = _stepCounter.steps;
      });
    });
  }

  void _onBackgroundFetch(String taskId) async {
    // Handle the background fetch event and update steps
    _updateStepsInBackground();
    BackgroundFetch.finish(taskId);
  }

  Future<void> _updateStepsInBackground() async {
    // Logic to update steps in background
    accelerometerEvents.listen((AccelerometerEvent event) {
      _stepCounter.onAccelerometerEvent(event.x, event.y, event.z);
      setState(() {
        _steps = _stepCounter.steps;
      });
    });

    // Save steps to local storage or Firebase if necessary
    await _updateCoinValue(_coinValue); // Update the local coin value
    _checkResetSteps(); // Check for step reset
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
            'date': _lastResetDate,
            'steps': _steps,
            'CoinsEarnedToday': (_steps / 3).toInt(),
          });
          await userDoc.update({
            'DailySteps': dailySteps,
            'CurrentDaySteps': 0,
            'LastResetDate': now,
            'Coins': FieldValue.increment((_steps / 3).toInt()),
          });
          setState(() {
            _steps = 0;
            _lastResetDate = now;
            _coinValue += (_steps / 3).toInt();
          });
          await _updateCoinValue(0); // Reset the local coin value
          _stepCounter.reset(); // Reset the step counter
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
              onTap: () {
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
              child: ListView.builder(
                itemCount: _widgetsStatus.length,
                itemBuilder: (context, index) {
                  final widgetStatus = _widgetsStatus[index];
                  if (widgetStatus['Status'] == 'Review') {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ReviewScreen()),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Image.asset('assets/Home/Review.png', height: 50),
                            SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widgetStatus['Heading'], style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface)),
                                Text(widgetStatus['SubHeading'], style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return GestureDetector(
                      onTap: _showComingSoonDialog,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Image.asset(widgetStatus['ImagePath'], height: 50),
                            SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widgetStatus['Heading'], style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface)),
                                Text(widgetStatus['SubHeading'], style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
