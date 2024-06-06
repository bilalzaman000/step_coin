//NotInUseDueToPasswordResetLink

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Widgets/SnackBar.dart';
import '../login/login.dart';

class UpdatePasswordScreen extends StatefulWidget {
  @override
  _UpdatePasswordScreenState createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  bool _isObscureNewPassword = true;
  bool _isObscureConfirmPassword = true;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fields cannot be empty')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    try {
      await _auth.currentUser?.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        customPasswordSnackbar(
          message: 'Password updated successfully',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          },
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Update Password',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/Lock.png',
                width: 100,
                height: 100,
              ),
              SizedBox(height: 30),
              TextField(
                controller: _newPasswordController,
                style: TextStyle(color: Colors.white),
                obscureText: _isObscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscureNewPassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscureNewPassword = !_isObscureNewPassword;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _confirmPasswordController,
                style: TextStyle(color: Colors.white),
                obscureText: _isObscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscureConfirmPassword = !_isObscureConfirmPassword;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.white),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Update Password',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
