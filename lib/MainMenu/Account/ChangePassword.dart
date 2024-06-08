import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Change Password'),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Text('Change Password Screen', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
