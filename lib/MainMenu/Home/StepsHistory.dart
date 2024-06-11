import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class StepsHistory extends StatefulWidget {
  @override
  _StepsHistoryState createState() => _StepsHistoryState();
}

class _StepsHistoryState extends State<StepsHistory> {
  List<dynamic> _stepsData = [];

  @override
  void initState() {
    super.initState();
    _fetchStepsData();
  }

  Future<void> _fetchStepsData() async {
    print('Entering _fetchStepsData');
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (snapshot.exists) {
        print('Document exists');
        final data = snapshot.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('DailySteps')) {
          print('DailySteps field exists');
          setState(() {
            _stepsData = (data['DailySteps'] as List<dynamic>? ?? [])
                .map((e) => {
              'date': (e['date'] as Timestamp).toDate(),
              'steps': e['steps'],
              'coins': e['coins']
            })
                .toList();
            _stepsData.sort((a, b) => b['date'].compareTo(a['date']));
            if (_stepsData.length > 7) {
              _stepsData = _stepsData.sublist(0, 7);
            }
            print('_stepsData: $_stepsData');
          });
        } else {
          print('DailySteps field does not exist');
        }
      } else {
        print('Document does not exist');
      }
    }
  }

  List<BarChartGroupData> _generateBarGroups() {
    return _stepsData.map((data) {
      final steps = data['steps'].toDouble();
      final coins = data['coins'].toDouble();
      return BarChartGroupData(
        x: _stepsData.indexOf(data),
        barRods: [
          BarChartRodData(
            toY: steps,
            color: Colors.blue,
            width: 10,
          ),
          BarChartRodData(
            toY: coins,
            color: Colors.yellow,
            width: 10,
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Steps History'),
        backgroundColor: theme.brightness == Brightness.light ? Colors.white : Colors.black,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: _stepsData.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_walk, size: 100, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                'No steps data available yet.\n Come Back Tomorrow to see your progress here!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        )
            : BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 16,
                      child: Text(
                        _stepsData[value.toInt()]['date'].toString().substring(0, 10),
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 16,
                      child: Text(
                        value.toString(),
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: false,
            ),
            barGroups: _generateBarGroups(),
          ),
        ),
      ),
    );
  }
}
