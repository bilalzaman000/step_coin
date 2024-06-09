import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../MainMenu.dart';
import '../NewUser/CreateUser.dart';
import '../reset/reset_email_screen.dart';
import '../Theme/ThemeProvider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscure = true;
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _email;
  late String _password;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    // Define colors based on the current theme
    Color appBarColor = theme.brightness == Brightness.light ? Colors.white : Colors.black;
    Color buttonBackgroundColor = Colors.black;
    Color buttonTextColor = Colors.white;
    Color scaffoldBackgroundColor = theme.brightness == Brightness.light ? Colors.white : Colors.black;
    Color textColor = theme.textTheme.bodyLarge!.color!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/Login/YellowRectangle.png',
                    width: 20,
                    height: 200,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'StepCoin',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 0),
              Text(
                'Login To Your Account',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: textColor),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: textColor),
                        ),
                      ),
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
                    SizedBox(height: 10),
                    TextFormField(
                      style: TextStyle(color: textColor),
                      obscureText: _isObscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: textColor),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: textColor),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscure ? Icons.visibility : Icons.visibility_off,
                            color: textColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _isObscure = !_isObscure;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _password = value;
                      },
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ResetPasswordScreen()),
                        );
                      },
                      child: Text(
                        'Forgot your Password?',
                        textAlign: TextAlign.end,
                        style: TextStyle(color: textColor),
                      ),
                    ),
                    SizedBox(height: 20),
                    _isLoading
                        ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    )
                        : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonBackgroundColor,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: textColor),
                        ),
                      ),
                      child: Text(
                        'Login',
                        style: TextStyle(color: buttonTextColor),
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
                            'assets/Login/google.png',
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
                            'assets/Login/apple.png',
                            width: 60,
                            height: 60,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: () {
                // Handle creating a new account
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateUserScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonBackgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: textColor),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  'Create A New Account',
                  style: TextStyle(color: buttonTextColor),
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Image.asset(
            'assets/HomeBar.png',
            width: 100, // Adjust the width as needed
            height: 50, // Adjust the height as needed
          ),
        ],
      ),
    );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login successful'),
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
    }
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
          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            'Coins': 0,
            'Name': userName,
            'Review_Coins':0,
            'Ad_Coins':0,
            'Redeemed_Coins':0,
            'Cashed_Coins':0,
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
