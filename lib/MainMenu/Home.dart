import 'package:flutter/material.dart';
import '../adManager.dart';
import 'Home/GiveReview.dart'; // Import the AdManager

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                AdManager().showRewardedAd(context);
              },
              child: Text('Watch Ad'), // Text for the button
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                AdManager().showRewardedAd(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ReviewScreen()),
                );// Call showRewardedAd method from AdManager
              },
              child: Text('Review Screen'), // Text for the button
            ),
          ],
        ),
      ),
    );
  }
}
