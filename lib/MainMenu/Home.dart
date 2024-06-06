import 'package:flutter/material.dart';


import '../adManager.dart'; // Import the AdManager

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
                AdManager().showRewardedAd(context); // Call showRewardedAd method from AdManager
              },
              child: Text('Watch Ad'), // Text for the button
            ),
            SizedBox(height: 20),
            Text(
              'Home Page',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
