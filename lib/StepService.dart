import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StepService {
  static Future<void> resetSteps(int stepsDivider) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      final DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
      final DocumentSnapshot snapshot = await userDoc.get();

      if (snapshot.exists) {
        final int currentSteps = prefs.getInt('steps') ?? 0;
        final int coinsEarnedToday = (currentSteps / stepsDivider).toInt();
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
        });
        prefs.setInt('coinValue', (prefs.getInt('coinValue') ?? 0) + coinsEarnedToday);
        prefs.setInt('steps', 0);
        prefs.setString('lastResetDate', now.toIso8601String());
        prefs.setInt('initialSteps', 0);
        // Log to indicate reset steps
        print('\x1B[31mSteps reset at midnight\x1B[0m');
      }
    }
  }
}
