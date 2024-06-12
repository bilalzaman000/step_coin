import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StepsHistory extends StatefulWidget {
  @override
  _StepsHistoryState createState() => _StepsHistoryState();
}

class _StepsHistoryState extends State<StepsHistory> {
  List<Map<String, dynamic>> _stepHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchStepHistory();
  }

  Future<void> _fetchStepHistory() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (snapshot.exists) {
        List<dynamic> dailySteps = snapshot['DailySteps'] ?? [];
        setState(() {
          _stepHistory = dailySteps.map((entry) => {
            'date': entry['date'],
            'steps': entry['steps'],
            'coins': entry['coins'],
          }).toList().reversed.toList(); // Show the latest data first
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Step History'),
      ),
      body: ListView.builder(
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
    );
  }
}
