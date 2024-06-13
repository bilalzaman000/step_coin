import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'Redemption/PaymentEmailScreen.dart';
import '../../Theme/ThemeProvider.dart';

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.getTheme();
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDarkTheme ? theme.appBarTheme.backgroundColor : Colors.white,
        title: FutureBuilder<Map<String, int>>(
          future: _fetchUserCoins(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: isDarkTheme ? Colors.white : Colors.black));
            } else if (snapshot.hasError) {
              return Text('Error', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black));
            } else {
              int coins = snapshot.data?['Coins'] ?? 0;
              int cashedCoins = snapshot.data?['Cashed_Coins'] ?? 0;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _tabController.index == 0
                    ? [
                  Text('StepsCoins', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black)),
                  Row(
                    children: [
                      Image.asset('assets/Coin.png', height: 24),
                      SizedBox(width: 8),
                      Text('$coins', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black)),
                    ],
                  ),
                ]
                    : [
                  Text('Cashed Coins', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black)),
                  Row(
                    children: [
                      Image.asset('assets/Coin.png', height: 24),
                      SizedBox(width: 8),
                      Text('$cashedCoins', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black)),
                    ],
                  ),
                ],
              );
            }
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: isDarkTheme ? Colors.white : Colors.black,
          labelColor: isDarkTheme ? Colors.white : Colors.black,
          unselectedLabelColor: isDarkTheme ? Colors.white70 : Colors.black54,
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
  Future<List<Map<String, dynamic>>> _fetchRewardRatios() async {
    List<String> docIds = ['Redeem', 'Redeem2', 'Redeem3'];
    List<Map<String, dynamic>> rewardRatios = [];

    for (String docId in docIds) {
      try {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('RewardRatio').doc(docId).get();
        if (snapshot.exists) {
          rewardRatios.add({
            'value': snapshot['Coins'],
            'dollars': snapshot['Dollars'],
          });
        } else {
          print('Document $docId does not exist');
        }
      } catch (e) {
        print('Error fetching document $docId: $e');
        throw e;
      }
    }
    return rewardRatios;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).getTheme();
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchRewardRatios(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: isDarkTheme ? Colors.white : Colors.black));
          } else if (snapshot.hasError) {
            print('Error loading rewards: ${snapshot.error}');
            return Center(
                child: Text('Error loading rewards', style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black)));
          } else {
            List<Map<String, dynamic>> rewardRatios = snapshot.data ?? [];
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: rewardRatios.length,
              itemBuilder: (context, index) {
                var reward = rewardRatios[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentEmailScreen(
                          title: 'PayPal Transfer',
                          value: '\$${reward['dollars']}',
                          tagValue: reward['value'],
                        ),
                      ),
                    );
                  },
                  child: RedemptionTile(
                    imageUrl: 'assets/Redemptions/PayPal.png',
                    title: 'PayPal Transfer',
                    value: '\$${reward['dollars']}',
                    description: 'Coupons directly on your email',
                    tagValue: reward['value'].toString(),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class RedeemedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).getTheme();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(child: Text('Redeemed Content', style: theme.textTheme.bodyLarge)),
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
    final theme = Provider.of<ThemeProvider>(context).getTheme();
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Card(
      color: isDarkTheme ? Colors.black87 : Colors.white,
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
                    color: isDarkTheme ? Colors.grey : Colors.black45,
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
            child: Text(title, style: theme.textTheme.bodyLarge),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(description, style: theme.textTheme.bodyLarge),
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
    final theme = Provider.of<ThemeProvider>(context).getTheme();

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
