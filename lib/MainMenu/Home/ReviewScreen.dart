import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Api/ReviewApi/FetchData.dart';
import 'AppClass.dart';
import 'Review/AppDetails.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Review/InfoReview.dart';
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
  bool isReviewedLoading = true;
  int totalRedeemedCoins = 0;
  int reviewCoinValue = 500; // Default value

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchReviewCoinValue();
    fetchApps().then((apps) {
      if (mounted) {
        setState(() {
          allApps = apps;
          isLoading = false;
        });
        filterReviewedApps();
        showSortingPopup();
      }
    });
    FirebaseFirestore.instance.collection('Reviews').snapshots().listen((snapshot) {
      if (mounted) {
        filterReviewedApps();
      }
    });

    _tabController.addListener(() {
      if (_tabController.index == 1) {
        fetchRedeemedCoins();
      }
      if (_tabController.index == 0) {
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  Future<void> fetchReviewCoinValue() async {
    final reviewDoc = await FirebaseFirestore.instance.collection('RewardRatio').doc('Review').get();
    if (reviewDoc.exists && reviewDoc.data() != null) {
      if (mounted) {
        setState(() {
          reviewCoinValue = reviewDoc.data()!['value'] ?? 0;
        });
      }
    }
  }

  Future<void> filterReviewedApps() async {
    if (mounted) {
      setState(() {
        isReviewedLoading = true;
      });
    }

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

    if (mounted) {
      setState(() {
        reviewedApps = reviewed;
        allApps = unreviewed;
        isReviewedLoading = false;
      });
    }
  }

  Future<void> fetchRedeemedCoins() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data() != null) {
      if (mounted) {
        setState(() {
          totalRedeemedCoins = userDoc.data()!['Redeemed_Coins'] ?? 0;
        });
      }
    }
  }

  Future<void> showSortingPopup() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Text('Please Wait'),
            content: Text('Data is being sorted...'),
          ),
        );
      },
    );

    await Future.delayed(Duration(seconds: 5));

    if (mounted) {
      Navigator.of(context).pop();
    }
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

  Future<String?> getReviewStatus(String userId, int orderId) async {
    final result = await FirebaseFirestore.instance
        .collection('Reviews')
        .doc(userId)
        .collection('Submissions')
        .where('orderId', isEqualTo: orderId)
        .get();

    if (result.docs.isNotEmpty) {
      return result.docs.first['ReviewStatus'] as String?;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.getTheme();
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDarkTheme ? theme.appBarTheme.backgroundColor : Colors.white, // Set to white in light mode
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
                    _tabController.index == 0 ? '$reviewCoinValue' : '$totalRedeemedCoins',
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
                        _tabController.index == 0 ? 'per Review' : 'you earned',
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
                indicatorColor: isDarkTheme ? Colors.white : Colors.black,
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
          buildAppList(allApps, theme, false),
          isReviewedLoading
              ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(isDarkTheme ? Colors.white : Colors.black),
            ),
          )
              : buildAppList(reviewedApps, theme, true),
        ],
      ),
    );
  }

  Widget buildAppList(List<AppInfo> apps, ThemeData theme, bool isReviewedTab) {
    if (apps.isEmpty) {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/Complete.png'),
              SizedBox(height: 20), // Add some spacing between the image and text
              Text(
                'No completed Reviews',
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'You haven’t completed any reviews',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        return FutureBuilder<String?>(
          future: isReviewedTab ? getReviewStatus(FirebaseAuth.instance.currentUser!.uid, app.orderId) : Future.value(null),
          builder: (context, snapshot) {
            String? reviewStatus = snapshot.data;

            return GameTile(
              game: Game(
                name: app.appTitle,
                imagePath: app.iconUrl,
                description: '',
                appURL: app.appURL,
                orderId: app.orderId,
                reviewStatus: reviewStatus,
              ),
              onTap: () {
                if (isReviewedTab) {
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
                          description: 'Please Download The App, Give 5 Star Rating, Write A Good Review, Submit the review And get $reviewCoinValue Coins As Rewards',
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
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class GameTile extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;

  GameTile({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).getTheme();
    final isDarkTheme = theme.brightness == Brightness.dark;

    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'approved':
          return Colors.green;
        case 'rejected':
          return Colors.red;
        case 'in review':
          return Colors.orangeAccent;
        default:
          return Colors.grey;
      }
    }

    Color getBorderColor(String status) {
      switch (status.toLowerCase()) {
        case 'approved':
          return Colors.green;
        case 'rejected':
          return Colors.red;
        case 'in review':
          return Colors.orangeAccent; // Use yellow color for "in review" status
        default:
          return Colors.grey;
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDarkTheme ? theme.cardColor : Color(0xFFFAFAFB), // Set container color in light mode
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
        trailing: game.reviewStatus != null
            ? Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: getStatusColor(game.reviewStatus!),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: getBorderColor(game.reviewStatus!), width: 2), // Set border color based on status
          ),
          child: Text(
            game.reviewStatus!,
            style: TextStyle(color: Colors.white),
          ),
        )
            : Icon(Icons.arrow_forward_ios, color: theme.iconTheme.color),
        onTap: onTap,
      ),
    );
  }
}
