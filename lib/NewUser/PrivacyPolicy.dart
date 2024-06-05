import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Privacy Policy'),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'This is the Privacy Policy screen.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
