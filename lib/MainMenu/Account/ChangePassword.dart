import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../Theme/ThemeProvider.dart';
import '../../reset/reset_email_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}
class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _oldPasswordController = TextEditingController();
  TextEditingController _newPasswordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();
  bool _isOldPasswordObscure = true;
  bool _isNewPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;
  User? user;
  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
  }
  void _changePassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        String email = user!.email!;
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: _oldPasswordController.text,
        );
        await user!.reauthenticateWithCredential(credential);
        await user!.updatePassword(_newPasswordController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password successfully updated')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    bool isGoogleSignIn =  user?.providerData.any((provider) => provider.providerId == 'google.com') ?? false;
    Color textColor = theme.textTheme.bodyLarge!.color!;
    Color buttonTextColor = theme.brightness == Brightness.light ? Colors.white : Colors.black;
    Color buttonBackgroundColor = theme.brightness == Brightness.light ? Colors.black : Colors.white;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.brightness == Brightness.light ? Colors.white : Colors.black,
        title: Text('Change Password', style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - kToolbarHeight,
            ),
            child: IntrinsicHeight(
              child: isGoogleSignIn
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'WooooHo!',
                    style: TextStyle(color: textColor, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'You are using Google Sign In, no need to remember a password.',
                    style: TextStyle(color: textColor, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
                  : Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/Lock.png', // Update this with the correct path to your lock image
                      width: 80,
                      height: 80,
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _oldPasswordController,
                      obscureText: _isOldPasswordObscure,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Old Password',
                        labelStyle: TextStyle(color: textColor),
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isOldPasswordObscure ? Icons.visibility : Icons.visibility_off,
                            color: textColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _isOldPasswordObscure = !_isOldPasswordObscure;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your old password';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _isNewPasswordObscure,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: TextStyle(color: textColor),
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isNewPasswordObscure ? Icons.visibility : Icons.visibility_off,
                            color: textColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _isNewPasswordObscure = !_isNewPasswordObscure;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your new password';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _isConfirmPasswordObscure,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: TextStyle(color: textColor),
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordObscure ? Icons.visibility : Icons.visibility_off,
                            color: textColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordObscure = !_isConfirmPasswordObscure;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your new password';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ResetPasswordScreen()),
                          );
                        },
                        child: Text(
                          'Forget Your Password?',
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: buttonTextColor,
                        backgroundColor: buttonBackgroundColor,
                        minimumSize: Size(double.infinity, 50), // Make the button expanded
                      ),
                      child: Text('Confirm'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
