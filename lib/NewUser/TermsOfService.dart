import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Terms of Conditions'),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'This is the Terms of Conditions screen.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
