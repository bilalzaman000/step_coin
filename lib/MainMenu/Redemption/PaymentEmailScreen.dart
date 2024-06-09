import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  Future<String> _getPayPalAccessToken() async {
    final clientId = 'YOUR_PAYPAL_SANDBOX_CLIENT_ID';
    final secret = 'YOUR_PAYPAL_SANDBOX_SECRET';
    final credentials = base64Encode(utf8.encode('$clientId:$secret'));

    final response = await http.post(
      Uri.parse('https://api.sandbox.paypal.com/v1/oauth2/token'),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials',
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['access_token'];
    } else {
      throw Exception('Failed to obtain PayPal access token');
    }
  }

  Future<void> _sendPayPalPayout(String email, String amount) async {
    final accessToken = await _getPayPalAccessToken();
    final response = await http.post(
      Uri.parse('https://api.sandbox.paypal.com/v1/payments/payouts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        "sender_batch_header": {
          "sender_batch_id": "Payouts_${DateTime.now().millisecondsSinceEpoch}",
          "email_subject": "You have a payout!",
        },
        "items": [
          {
            "recipient_type": "EMAIL",
            "amount": {
              "value": amount,
              "currency": "USD",
            },
            "receiver": email,
            "note": "Thanks for your participation!",
            "sender_item_id": "item_1",
          },
        ],
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to send PayPal payout');
    }
  }

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
        await userDoc.update({'Coins': coins - widget.tagValue});

        await _sendPayPalPayout(_emailController.text, widget.value.substring(1));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Coupon sent successfully!')),
        );
        Navigator.pop(context);  // Go back after successful redemption
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
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Redeem Coins')),
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
              Text('Enter your PayPal email to receive the coupon:', style: TextStyle(color: Colors.white)),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
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
                style: TextStyle(color: Colors.white),
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
                child: Text('Submit', style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
