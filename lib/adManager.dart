import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdManager {
  static final AdManager _instance = AdManager._internal();

  factory AdManager() {
    return _instance;
  }

  AdManager._internal();

  late RewardedAd _rewardedAd;
  bool _isRewardedAdReady = false;

  void initialize() {
    MobileAds.instance.initialize();
    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-2280018091941532/3446966317', // Your ad unit ID
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdReady = false;
          print('RewardedAd failed to load: $error');
        },
      ),
    );
  }
  void showRewardedAd(BuildContext context, VoidCallback onAdCompleted) {
    if (_isRewardedAdReady) {
      _rewardedAd.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          print('RewardedAd showed full screen content.');
        },
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadRewardedAd(); // Load a new ad after the previous one is dismissed.
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          print('RewardedAd failed to show: $error');
          _loadRewardedAd(); // Load a new ad if the previous one fails to show.
        },
      );

      _rewardedAd.show(onUserEarnedReward: (ad, reward) async {
        print('User earned reward: $reward');
        await _handleReward(context);
        onAdCompleted(); // Call the callback after the ad is completed
      });

      _isRewardedAdReady = false;
    } else {
      print('RewardedAd is not ready.');
    }
  }




  Future<void> _handleReward(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

      FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userDoc);

        if (snapshot.exists) {
          int currentAdCoins = snapshot.get('Ad_Coins') ?? 0;
          int currentCoins = snapshot.get('Coins') ?? 0;

          transaction.update(userDoc, {
            'Ad_Coins': currentAdCoins + 50,
            'Coins': currentCoins + 50,
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        customPasswordSnackbar(
          message: 'Congratulations! You have earned 50 Coins',
          onPressed: () {},
        ),
      );
    } else {
      print('No user is signed in.');
    }
  }

  void updateRequestConfiguration() {
    final List<String> testDeviceIds = [
      '92DF66844DEC83C18072DAF5C8718BD6', // Add your test device IDs here
    ];

    final RequestConfiguration requestConfiguration = RequestConfiguration(
      testDeviceIds: testDeviceIds,
    );

    MobileAds.instance.updateRequestConfiguration(requestConfiguration);
  }
}

SnackBar customPasswordSnackbar({required String message, required VoidCallback onPressed}) {
  return SnackBar(
    content: Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15.0), // Adjust the radius as needed
            child: Image.asset(
              'assets/ExclaimationMark.png',
              width: 50,
              height: 50,
            ),
          ),
          SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 10),
        ],
      ),
    ),
    behavior: SnackBarBehavior.floating,
    duration: Duration(seconds: 3),
    backgroundColor: Colors.grey[850],  // Light black/grey color
  );
}
