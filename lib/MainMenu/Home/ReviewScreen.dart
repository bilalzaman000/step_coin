import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Api/ReviewApi/FetchData.dart';
import 'AppClass.dart';
import 'Review/AppDetails.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Review/InfoReview.dart'; // Import the InfoReview.dart file
import '../../Theme/ThemeProvider.dart';

class ReviewScreen extends StatefulWidget {
  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AppInfo> allApps = [];
  List<AppInfo> reviewedApps = [];
  bool isLoading = true;
  bool isReviewedLoading = true; // Change to true initially

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchApps().then((apps) {
      setState(() {
        allApps = apps;
        isLoading = false;
      });
      filterReviewedApps();
    });
    FirebaseFirestore.instance.collection('Reviews').snapshots().listen((snapshot) {
      filterReviewedApps();
    });
  }

  Future<void> filterReviewedApps() async {
    setState(() {
      isReviewedLoading = true; // Set loading to true initially
    });

    String userId = FirebaseAuth.instance.currentUser!.uid;
    List<AppInfo> reviewed = [];
    List<AppInfo> unreviewed = [];
    for (var app in allApps) {
      bool isReviewed = await hasReviewed(userId, app.orderId);
      if (isReviewed) {
        reviewed.add(app);
      } else {
        unreviewed.add(app);
      }
    }
    setState(() {
      reviewedApps = reviewed;
      allApps = unreviewed; // Update allApps to only include unreviewed apps
      isReviewedLoading = false; // Set loading to false after filtering
    });
  }

  Future<bool> hasReviewed(String userId, int orderId) async {
    final result = await FirebaseFirestore.instance
        .collection('Reviews')
        .doc(userId)
        .collection('Submissions')
        .where('orderId', isEqualTo: orderId)
        .get();

    return result.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.getTheme();
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Give A Review',
          style: theme.appBarTheme.titleTextStyle,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(130.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/Coin.png', width: 50, height: 50),
                  SizedBox(width: 8),
                  Text(
                    '500',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white : Colors.black,
                      fontSize: 50,
                    ),
                  ),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coins',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'per Review',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.grey : Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              TabBar(
                controller: _tabController,
                labelColor: isDarkTheme ? Colors.white : Colors.black,
                unselectedLabelColor: isDarkTheme ? Colors.white70 : Colors.black54,
                indicatorColor: isDarkTheme ? Colors.white : Colors.black, // Set indicator color based on theme
                tabs: [
                  Tab(text: 'All Apps'),
                  Tab(text: 'Reviewed Apps'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(isDarkTheme ? Colors.white : Colors.black),
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          buildAppList(allApps, theme),
          isReviewedLoading
              ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(isDarkTheme ? Colors.white : Colors.black),
            ),
          )
              : buildAppList(reviewedApps, theme),
        ],
      ),
    );
  }

  Widget buildAppList(List<AppInfo> apps, ThemeData theme) {
    if (apps.isEmpty) {
      return Center(child: Text('No data found', style: theme.textTheme.bodyLarge));
    }

    return ListView.builder(
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        return GameTile(
          game: Game(
            name: app.appTitle,
            imagePath: app.iconUrl,
            description: '',
            appURL: app.appURL,
            orderId: app.orderId,
          ),
          onTap: () {
            if (_tabController.index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InfoReview(orderId: app.orderId.toString()),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppPage(
                    game: Game(
                      name: app.appTitle,
                      imagePath: app.iconUrl,
                      description: 'Please Download The App, Give 5 Star Rating, Write A Good Review, Submit the review And get 500 Coins As Rewards',
                      appURL: app.appURL,
                      orderId: app.orderId,
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}

class GameTile extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;

  GameTile({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).getTheme();
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: ClipOval(
            child: Image.network(
              game.imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          game.name,
          style: theme.textTheme.bodyLarge,
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: theme.iconTheme.color),
        onTap: onTap,
      ),
    );
  }
}


