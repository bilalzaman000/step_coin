import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoReview extends StatefulWidget {
  final String orderId;

  InfoReview({required this.orderId});

  @override
  _InfoReviewState createState() => _InfoReviewState();
}

class _InfoReviewState extends State<InfoReview> {
  late Future<int> _reviewCoinValueFuture;
  bool _isLoading = false; // Loading state

  @override
  void initState() {
    super.initState();
    _reviewCoinValueFuture = _fetchReviewCoinValue();
  }

  Future<int> _fetchReviewCoinValue() async {
    final reviewDoc = await FirebaseFirestore.instance.collection('RewardRatio').doc('Review').get();
    if (reviewDoc.exists && reviewDoc.data() != null) {
      return reviewDoc.data()!['value'] ?? 500;
    }
    return 500; // Default value if not found
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Review Info'),
      ),
      body: FutureBuilder<int>(
        future: _reviewCoinValueFuture,
        builder: (context, coinValueSnapshot) {
          if (coinValueSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (coinValueSnapshot.hasError) {
            return Center(child: Text('Error: ${coinValueSnapshot.error}'));
          } else {
            final reviewCoinValue = coinValueSnapshot.data ?? 500;

            return FutureBuilder<QuerySnapshot>(
              future: _fetchReviewDetails(),
              builder: (context, reviewSnapshot) {
                if (reviewSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (reviewSnapshot.hasError) {
                  return Center(child: Text('Error: ${reviewSnapshot.error}'));
                } else if (!reviewSnapshot.hasData || reviewSnapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No review found'));
                } else {
                  final docSnapshot = reviewSnapshot.data!.docs.first;
                  final data = docSnapshot.data() as Map<String, dynamic>;
                  final appName = data['appName'] ?? 'Unknown App';
                  final imageUrl = data['appImageURL'] ?? '';
                  final review = data['review'] ?? '';
                  final status = data['ReviewStatus'] ?? 'In Review';
                  final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final imageUrls = List<String>.from(data['images'] ?? []);
                  final isClaimed = data['claimed'] ?? false;

                  Color borderColor;
                  Color claimButtonColor;
                  String claimButtonText = 'Claim';
                  VoidCallback? onClaimPressed;

                  switch (status) {
                    case 'Approved':
                      borderColor = Colors.green;
                      if (isClaimed) {
                        claimButtonColor = Colors.grey;
                        claimButtonText = 'Claimed';
                        onClaimPressed = null;
                      } else {
                        claimButtonColor = Colors.yellow;
                        onClaimPressed = () => _claimReward(context, docSnapshot.id, reviewCoinValue);
                      }
                      break;
                    case 'Rejected':
                      borderColor = Colors.red;
                      claimButtonColor = Colors.grey;
                      onClaimPressed = null;
                      break;
                    case 'In Review':
                    default:
                      borderColor = Colors.orange;
                      claimButtonColor = Colors.grey;
                      onClaimPressed = null;
                      break;
                  }

                  Color coinTextColor = isDarkMode ? Colors.white : Colors.black;

                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  width: MediaQuery.of(context).size.width * 0.9,
                                  height: 150,
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                  )
                                      : Container(
                                    height: 200,
                                    color: Colors.grey,
                                    child: Icon(Icons.image_not_supported),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Center(
                                child: Text(
                                  appName,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset('assets/Coin.png', width: 50, height: 50),
                                  SizedBox(width: 8),
                                  Text(
                                    '$reviewCoinValue',
                                    style: TextStyle(
                                      color: coinTextColor,
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
                                          color: coinTextColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'Earned',
                                        style: TextStyle(
                                          color: coinTextColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  border: Border.all(color: borderColor, width: 2.0),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: TextFormField(
                                  initialValue: review,
                                  maxLines: 2,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Review Submitted: ${timestamp.toLocal()}',
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Uploaded Images:',
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 10),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: imageUrls.map((url) {
                                  return GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Dialog(
                                            child: Image.network(url),
                                          );
                                        },
                                      );
                                    },
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: borderColor, width: 2.0),
                                            borderRadius: BorderRadius.circular(8.0),
                                          ),
                                          child: Image.network(
                                            url,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                width: 100,
                                                height: 100,
                                                child: Center(
                                                  child: CircularProgressIndicator(
                                                    value: loadingProgress.expectedTotalBytes != null
                                                        ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes!)
                                                        : null,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: 20),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: borderColor, width: 2.0),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Text(
                                    'Review Status: $status',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Center(
                                child: ElevatedButton(
                                  onPressed: onClaimPressed,
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    backgroundColor: claimButtonColor,
                                    minimumSize: Size(MediaQuery.of(context).size.width * 0.8, 50),
                                  ),
                                  child: Text(claimButtonText),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isLoading)
                        Container(
                          color: Colors.black45,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  );
                }
              },
            );
          }
        },
      ),
    );
  }

  Future<QuerySnapshot> _fetchReviewDetails() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      print('Fetching review details for orderId: ${widget.orderId} with UID: $uid');
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Reviews')
          .doc(uid)
          .collection('Submissions')
          .where('orderId', isEqualTo: int.parse(widget.orderId)) // Ensure orderId is of the correct type
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print('Review found: ${querySnapshot.docs.first.data()}');
        return querySnapshot;
      } else {
        print('Review not found for orderId: ${widget.orderId}');
        throw Exception('Review not found');
      }
    } catch (e) {
      print('Error fetching review details: $e');
      throw e;
    }
  }

  Future<void> _claimReward(BuildContext context, String reviewId, int reviewCoinValue) async {
    try {
      setState(() {
        _isLoading = true; // Show loading indicator
      });

      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentReference reviewRef = FirebaseFirestore.instance
          .collection('Reviews')
          .doc(uid)
          .collection('Submissions')
          .doc(reviewId);

      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      // Check if the reward has already been claimed
      DocumentSnapshot reviewSnapshot = await reviewRef.get();
      if (reviewSnapshot.exists && (reviewSnapshot.get('claimed') ?? false) == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reward already claimed')),
        );
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
        return;
      }

      // Update the review document to mark it as claimed
      await reviewRef.update({'claimed': true});

      // Increment the user's coins and redeemed coins
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot userSnapshot = await transaction.get(userRef);
        if (userSnapshot.exists) {
          int currentCoins = userSnapshot.get('Coins') ?? 0;
          int currentRedeemedCoins = userSnapshot.get('Redeemed_Coins') ?? 0;

          transaction.update(userRef, {
            'Coins': currentCoins + reviewCoinValue,
            'Redeemed_Coins': currentRedeemedCoins + reviewCoinValue,
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Congratulations! Reward claimed!')),
      );
    } catch (e) {
      print('Error claiming reward: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error claiming reward')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }
}



