import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../Theme/ThemeProvider.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  User? user;
  bool _isLoading = true;
  bool _isGoogleSignIn = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _isGoogleSignIn = user?.providerData.any((provider) => provider.providerId == 'google.com') ?? false;
    _fetchUserData();
  }

  void _fetchUserData() async {
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      setState(() {
        _emailController.text = userDoc['Email'] ?? user!.email ?? '';
        _nameController.text = userDoc['Name'] ?? '';
        _isLoading = false;
      });
    }
  }

  void _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUpdating = true;
      });
      try {
        if (!_isGoogleSignIn) {
          await user!.updateEmail(_emailController.text);
        }
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
          'Name': _nameController.text,
          'Email': _emailController.text,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile successfully updated')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    Color textColor = theme.textTheme.bodyLarge!.color!;
    Color buttonTextColor = theme.brightness == Brightness.light ? Colors.white : Colors.black;
    Color buttonBackgroundColor = theme.brightness == Brightness.light ? Colors.black : Colors.white;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.brightness == Brightness.light ? Colors.white : Colors.black,
        title: Text('Edit Profile', style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _emailController,
                  enabled: !_isGoogleSignIn,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: textColor),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: textColor),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                _isUpdating
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: buttonTextColor,
                    backgroundColor: buttonBackgroundColor,
                    minimumSize: Size(double.infinity, 50), // Make the button expanded
                  ),
                  child: Text('Update'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
