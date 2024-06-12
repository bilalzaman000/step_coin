import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepsHistory extends StatefulWidget {
  @override
  _StepsHistoryState createState() => _StepsHistoryState();
}

class _StepsHistoryState extends State<StepsHistory> {
  List<Map<String, dynamic>> _stepHistory = [];
  int _currentSteps = 0;
  int _currentCoins = 0;

  @override
  void initState() {
    super.initState();
    _fetchStepHistory();
  }

  Future<void> _fetchStepHistory() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (uid != null) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (snapshot.exists) {
        List<dynamic> dailySteps = snapshot['DailySteps'] ?? [];
        setState(() {
          _stepHistory = dailySteps.map((entry) => {
            'date': entry['date'],
            'steps': entry['steps'],
            'coins': entry['coins'],
          }).toList().reversed.toList();
          _currentSteps = prefs.getInt('steps') ?? 0;
          _currentCoins = (_currentSteps / 3).toInt();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false, // hides the back button
        title: Center(
          child: Text('Step History', style: TextStyle(color: Colors.white)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
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
                  Text('Today Steps', style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface)),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/Home/Steps.png', height: 50),
                      SizedBox(width: 8),
                      Text('$_currentSteps', style: TextStyle(fontSize: 50, color: theme.colorScheme.onSurface)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/Coin.png', height: 24),
                      SizedBox(width: 8),
                      Text('$_currentCoins', style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface)),
                      SizedBox(width: 6),
                      Text('Earned Today', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text('Past 7 days', style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface)),
                  SizedBox(height: 10),
                  Expanded(child: _buildBarChart()),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _stepHistory.length,
                      itemBuilder: (context, index) {
                        final entry = _stepHistory[index];
                        return Card(
                          child: ListTile(
                            leading: Icon(Icons.directions_walk),
                            title: Text('Date: ${entry['date']}'),
                            subtitle: Text('Steps: ${entry['steps']}\nCoins: ${entry['coins']}'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
        BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: _stepHistory.isNotEmpty ? _stepHistory.map((e) => e['steps']).reduce((a, b) => a > b ? a : b).toDouble() : 10,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    rod.toY.toString(),
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold, backgroundColor: Colors.yellow),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < _stepHistory.length) {
                      final date = DateTime.parse(_stepHistory[index]['date']);
                      return Text(DateFormat('E').format(date), style: const TextStyle(color: Colors.white, fontSize: 10));
                    }
                    return Text('');
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: _stepHistory.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: data['steps'].toDouble(),
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.yellow],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 22,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
            }).toList(),
        ),
    );
  }
}

