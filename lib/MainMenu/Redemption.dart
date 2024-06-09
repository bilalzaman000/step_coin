import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'Redemption/PaymentEmailScreen.dart';

class RedemptionPage extends StatefulWidget {
  @override
  _RedemptionPageState createState() => _RedemptionPageState();
}

class _RedemptionPageState extends State<RedemptionPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  Future<Map<String, int>> _fetchUserCoins() async {
    User user = FirebaseAuth.instance.currentUser!;
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return {
      'Coins': snapshot['Coins'],
      'Cashed_Coins': snapshot['Cashed_Coins'],
    };

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: FutureBuilder<Map<String, int>>(
          future: _fetchUserCoins(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: Colors.white));
            } else if (snapshot.hasError) {
              return Text('Error', style: TextStyle(color: Colors.white));
            } else {
              int coins = snapshot.data?['Coins'] ?? 0;
              int cashedCoins = snapshot.data?['Cashed_Coins'] ?? 0;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _tabController.index == 0
                    ? [
                  Text('StepsCoins', style: TextStyle(color: Colors.white)),
                  Row(
                    children: [
                      Image.asset('assets/Coin.png', height: 24),
                      SizedBox(width: 8),
                      Text('$coins', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ]
                    : [
                  Text('Cashed Coins', style: TextStyle(color: Colors.white)),
                  Row(
                    children: [
                      Image.asset('assets/Coin.png', height: 24),
                      SizedBox(width: 8),
                      Text('$cashedCoins', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              );
            }
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Available'),
            Tab(text: 'Redeemed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AvailableTab(),
          RedeemedTab(),
        ],
      ),
    );
  }
}

class AvailableTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaymentEmailScreen(
                  title: 'PayPal Transfer',
                  value: '\$10',
                  tagValue: 1000,
                )),
              );
            },
            child: RedemptionTile(
              imageUrl: 'assets/Redemptions/PayPal.png',
              title: 'PayPal Transfer',
              value: '\$10',
              description: 'Coupons directly on your email',
              tagValue: '1000',
            ),
          ),
          SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaymentEmailScreen(
                  title: 'Amazon Gift Card',
                  value: '\$15',
                  tagValue: 1500,
                )),
              );
            },
            child: RedemptionTile(
              imageUrl: 'assets/Redemptions/PayPal.png',
              title: 'PayPal Transfer',
              value: '\$15',
              description: 'Coupons directly on your email',
              tagValue: '1500',
            ),
          ),
          SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaymentEmailScreen(
                  title: 'Google Play Gift Card',
                  value: '\$25',
                  tagValue: 2500,
                )),
              );
            },
            child: RedemptionTile(
              imageUrl: 'assets/Redemptions/PayPal.png',
              title: 'PayPal Transfer',
              value: '\$25',
              description: 'Coupons directly on your email',
              tagValue: '2500',
            ),
          ),
        ],
      ),
    );
  }
}

class RedeemedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: Text('Redeemed Content', style: TextStyle(color: Colors.white))),
    );
  }
}

class RedemptionTile extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String value;
  final String description;
  final String tagValue;

  const RedemptionTile({
    required this.imageUrl,
    required this.title,
    required this.value,
    required this.description,
    required this.tagValue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black87,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.asset(imageUrl, fit: BoxFit.cover),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Image.asset('assets/Coin.png', height: 16),
                      SizedBox(width: 4),
                      Text(tagValue, style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(title, style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(description, style: TextStyle(color: Colors.white)),
                Text(value, style: TextStyle(color: Colors.green, fontSize: 24)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final String title;

  DetailPage(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text('Details for $title'),
      ),
    );
  }
}
