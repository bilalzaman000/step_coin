import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../MainMenu.dart';
import '../welcomepage.dart';
import 'PrivacyPolicy.dart';
import 'TermsOfService.dart';

class CreateUserScreen extends StatefulWidget {
  @override
  _CreateUserScreenState createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _termsAccepted = false;
  bool _isLoading = false;  // Loading state flag
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  late String _email;
  late String _password;
  late String _confirmPassword;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: isDarkTheme ? Colors.black : Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDarkTheme ? Colors.white : Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        backgroundColor: isDarkTheme ? Colors.black : Colors.white,
        body: Stack(
            children: [
        Column(
        children: [
        Expanded(
        child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/NewUser/YellowRectangle.png',
                fit: BoxFit.contain,
              ),
              SizedBox(width: 10),
              Text(
                'StepCoin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkTheme ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 80),
          Center(
            child: Text(
              'Create Your Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkTheme ? Colors.white : Colors.black,
              ),
            ),
          ),
          SizedBox(height: 30),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: isDarkTheme ? Colors.white : Colors.black),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: isDarkTheme ? Colors.white : Colors.black),
              ),
            ),
            style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!isValidEmail(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
            onChanged: (value) {
              _email = value;
            },
          ),
          SizedBox(height: 15),
          TextFormField(
            obscureText: !_passwordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: isDarkTheme ? Colors.white : Colors.black),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: isDarkTheme ? Colors.white : Colors.black),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  color: isDarkTheme ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
              ),
            ),
            style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              _password = value;
              return null;
            },
          ),
          SizedBox(height: 15),
          TextFormField(
            obscureText: !_confirmPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              labelStyle: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: isDarkTheme ? Colors.white : Colors.black),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: isDarkTheme ? Colors.white : Colors.black),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: isDarkTheme ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    _confirmPasswordVisible = !_confirmPasswordVisible;
                  });
                },
              ),
            ),
            style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              _confirmPassword = value;
              if (_confirmPassword != _password) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          SizedBox(height: 15),
          Row(
            children: [
              Checkbox(
                value: _termsAccepted,
                onChanged: (value) {
                  setState(() {
                    _termsAccepted = value!;
                  });
                },
                checkColor: isDarkTheme ? Colors.black : Colors.white,
                activeColor: isDarkTheme ? Colors.white : Colors.black,
              ),
              Text(
                'I accept ',
                style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PrivacyPolicyScreen()),
                  );
                },
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Text(
                ' and ',
                style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            TermsConditionsScreen()),
                  );
                },
                child: Text(
                  'Terms of Service',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              child:ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    if (_termsAccepted) {
                      setState(() {
                        _isLoading = true;
                      });
                      try {
                        UserCredential userCredential =
                        await _auth
                            .createUserWithEmailAndPassword(
                          email: _email,
                          password: _password,
                        );
                        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
                          'Name': 'Null',
                          'Email': _email,
                          'Coins': 0,
                          'Review_Coins':0,
                          'Ad_Coins':0,
                          'Redeemed_Coins':0,
                          'Cashed_Coins':0,
                          'DailySteps': [], // Initialize as an empty list
                          'CurrentDaySteps': 0, // Initialize current day's steps as 0
                          'LastResetDate': FieldValue.serverTimestamp(),
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Account created successfully'),
                          ),
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => MainMenu()),
                        );
                      } on FirebaseAuthException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.message!),
                          ),
                        );
                      } finally {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please accept terms and conditions'),
                        ),
                      );
                    }
                  }
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
                  ),
                  foregroundColor: MaterialStateProperty.all<Color>(
                    Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.black,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text('Register'),
                ),
              ),


            ),
          ),
          SizedBox(height: 20),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              GestureDetector(
              onTap: () {
        _signInWithGoogle();
        },
          child: Image.asset(
            'assets/NewUser/google.png',
            width: 40,
            height: 50,
          ),
        ),
        SizedBox(width: 20),
        GestureDetector(
        onTap: () {
      // Handle Apple login
    },
    child: Image.asset(
    'assets/NewUser/apple.png',
      width: 60,
      height: 60,
    ),
        ),
              ],
          ),
            ],
          ),
        ),
        ),
        ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.only(bottom: 20),
              child: Image.asset(
                'assets/HomeBar.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
        ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
            ],
        ),
    );
  }

  bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+$").hasMatch(email);
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true; // Set loading state when starting sign-in process
    });
    try {
      final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );
        final UserCredential userCredential =
        await _auth.signInWithCredential(credential);

        // Check if user is new or existing and navigate accordingly
        if (userCredential.additionalUserInfo!.isNewUser) {
          // Handle new user
          // Add user data to Firestore
          final String? userName = googleSignInAccount.displayName;
          final String? email = googleSignInAccount.email;
          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            'Coins': 0,
            'Name': userName,
            'Email': email, // Store the user's email
            'Review_Coins': 0,
            'Ad_Coins': 0,
            'Redeemed_Coins': 0,
            'Cashed_Coins': 0,
            'DailySteps': [], // Initialize as an empty list
            'CurrentDaySteps': 0, // Initialize current day's steps as 0
            'LastResetDate': FieldValue.serverTimestamp(),
          });
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainMenu()),
          );
          // Navigate to a different screen or perform any action
        } else {
          // Handle existing user
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainMenu()),
          );
        }
      }
    } catch (error) {
      print('Error signing in with Google: $error');
    } finally {
      setState(() {
        _isLoading = false; // Set loading state to false after sign-in process completes
      });
    }
  }

}

