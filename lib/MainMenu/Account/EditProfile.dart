import 'package:flutter/material.dart';

class EditProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Edit Profile'),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Text('Edit Profile Screen', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
