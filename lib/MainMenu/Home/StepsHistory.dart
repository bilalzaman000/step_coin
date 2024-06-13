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
  String _selectedDaySteps = '';
  String _selectedDayCoins = '';

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

        // Filter out records older than 7 days
        DateTime sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
        List<Map<String, dynamic>> filteredSteps = dailySteps.where((entry) {
          DateTime date;
          if (entry['date'] is Timestamp) {
            date = (entry['date'] as Timestamp).toDate();
          } else if (entry['date'] is String) {
            date = DateTime.parse(entry['date']);
          } else {
            return false;
          }
          return date.isAfter(sevenDaysAgo);
        }).map((entry) {
          DateTime date;
          if (entry['date'] is Timestamp) {
            date = (entry['date'] as Timestamp).toDate();
          } else if (entry['date'] is String) {
            date = DateTime.parse(entry['date']);
          } else {
            date = DateTime.now(); // Fallback in case of an unexpected type
          }
          return {
            'date': date,
            'steps': entry['steps'],
            'coins': entry['coins'],
          };
        }).toList();

        // Limit to the last 7 records
        if (filteredSteps.length > 7) {
          filteredSteps = filteredSteps.sublist(filteredSteps.length - 7);
        }

        setState(() {
          _stepHistory = filteredSteps.reversed.toList();
          _currentSteps = prefs.getInt('steps') ?? 0;
          _currentCoins = (_currentSteps / 3).toInt();

          // Default to current day
          if (_stepHistory.isNotEmpty) {
            _selectedDaySteps = _stepHistory[0]['steps'].toString();
            _selectedDayCoins = _stepHistory[0]['coins'].toString();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLightTheme = theme.brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isLightTheme ? Colors.white : Colors.black,
        automaticallyImplyLeading: false, // hides the back button
        title: Center(
          child: Text('Step History', style: TextStyle(color: isLightTheme ? Colors.black : Colors.white)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildBarChart(isLightTheme),
              ),
            ),
            if (_selectedDaySteps.isNotEmpty && _selectedDayCoins.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: isLightTheme ? Color(0xFFFAFAFB) : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Steps and Coins', style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface)),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/Home/Steps.png', height: 50),
                        SizedBox(width: 8),
                        Text(_selectedDaySteps, style: TextStyle(fontSize: 50, color: theme.colorScheme.onSurface)),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/Coin.png', height: 24),
                        SizedBox(width: 8),
                        Text(_selectedDayCoins, style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface)),
                        SizedBox(width: 6),
                        Text('Earned Today', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface)),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(bool isLightTheme) {
    double maxY = _stepHistory.isNotEmpty
        ? (_stepHistory.map((e) => e['steps']).reduce((a, b) => a > b ? a : b) + 50).toDouble()
        : 10;
    double minY = 0; // Set the minimum Y value to lift the bars above the x-axis
    double paddingBelowAxis = 30; // Additional padding below the chart

    return Container(
      height: MediaQuery.of(context).size.height * 0.35, // Adjusted to make the bar chart smaller
      decoration: BoxDecoration(
        color: isLightTheme ? Color(0xFFFAFAFB) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: paddingBelowAxis), // Add padding below the chart
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            minY: minY,
            maxY: maxY,
            barTouchData: BarTouchData(
              touchCallback: (FlTouchEvent event, barTouchResponse) {
                if (event.isInterestedForInteractions &&
                    barTouchResponse != null &&
                    barTouchResponse.spot != null) {
                  final touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                  final steps = _stepHistory[touchedIndex]['steps'].toString();
                  final coins = _stepHistory[touchedIndex]['coins'].toString();
                  setState(() {
                    _selectedDaySteps = steps;
                    _selectedDayCoins = coins;
                  });
                }
              },
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final index = group.x.toInt();
                  if (index >= 0 && index < _stepHistory.length) {
                    final entry = _stepHistory[index];
                  }
                  return null;
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < _stepHistory.length) {
                      final date = _stepHistory[index]['date'];
                      return Column(
                        children: [
                          Text(DateFormat('E').format(date), style: TextStyle(color: isLightTheme ? Colors.black : Colors.white, fontSize: 14)),
                          SizedBox(height: 4),
                        ],
                      );
                    }
                    return Text('');
                  },
                ),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(
                  color: isLightTheme ? Colors.black : Colors.white,
                  width: 2,
                ),
              ),
            ),
            gridData: FlGridData(show: false),
            barGroups: _stepHistory.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              final isCurrentDay = index == 0; // The last bar is the current day in reversed list
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: data['steps'].toDouble(),
                    gradient: LinearGradient(
                      colors: isCurrentDay
                          ? [Colors.orange, Colors.yellow]
                          : [Colors.lightBlueAccent, Colors.purple],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    width: 25,
                    borderRadius: BorderRadius.circular(200), // Fully rounded bars
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: minY,
                      color: Colors.transparent,
                    ),
                  ),
                ],
                showingTooltipIndicators: [0],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
