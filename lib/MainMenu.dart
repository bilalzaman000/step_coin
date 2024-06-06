import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login/login.dart';


class MainMenu extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Menu'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'Welcome to the Main Menu.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
