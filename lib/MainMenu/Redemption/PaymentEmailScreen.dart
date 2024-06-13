import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:provider/provider.dart';
import '../../Theme/ThemeProvider.dart';

class PaymentEmailScreen extends StatefulWidget {
  final String title;
  final String value;
  final int tagValue;

  PaymentEmailScreen({required this.title, required this.value, required this.tagValue});

  @override
  _PaymentEmailScreenState createState() => _PaymentEmailScreenState();
}

class _PaymentEmailScreenState extends State<PaymentEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _redeemCoins() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User user = FirebaseAuth.instance.currentUser!;
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      DocumentSnapshot snapshot = await userDoc.get();

      int coins = snapshot['Coins'];
      if (coins >= widget.tagValue) {
        print('Coins: $coins');
        print('Tag Value: ${widget.tagValue}');
        print('Dollar Value: ${widget.value}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data printed successfully!')),
        );
        // Navigate back after successful redemption (you can comment this out if you don't want to navigate back)
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough coins')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.getTheme();
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Redeem Coins')),
        backgroundColor: isDarkTheme ? theme.scaffoldBackgroundColor : Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/Redeem.png', height: 100),
              SizedBox(height: 20),
              Text(
                'Enter your PayPal email to receive the coupon:',
                style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
              ),
              SizedBox(height: 20),
              Text(
                'Coins Required: ${widget.tagValue}',
                style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black, fontSize: 18),
              ),
              SizedBox(height: 10),
              Text(
                'Dollar Value: ${widget.value}',
                style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black, fontSize: 18),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: isDarkTheme ? Colors.white : Colors.black),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: isDarkTheme ? Colors.white : Colors.black),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  } else if (!EmailValidator.validate(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
              ),
              SizedBox(height: 20),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _redeemCoins();
                  }
                },
                child: Text(
                  'Submit',
                  style: TextStyle(color: isDarkTheme ? Colors.black : Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkTheme ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
