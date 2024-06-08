import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoReview extends StatelessWidget {
  final String orderId;

  InfoReview({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review Info'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _fetchReviewDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No review found'));
          } else {
            final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
            final appName = data['appName'] ?? 'Unknown App';
            final imageUrl = data['appImageURL'] ?? '';
            final appUrl = data['appURL'] ?? '';
            final review = data['review'] ?? '';
            final status = data['ReviewStatus'] ?? 'In Review';
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            final imageUrls = List<String>.from(data['images'] ?? []);

            Color borderColor;
            Color claimButtonColor;

            switch (status) {
              case 'Approved':
                borderColor = Colors.green;
                claimButtonColor = Colors.yellow;
                break;
              case 'Rejected':
                borderColor = Colors.red;
                claimButtonColor = Colors.grey;
                break;
              case 'In Review':
              default:
                borderColor = Colors.orange;
                claimButtonColor = Colors.grey;
                break;
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.6,
                        height: 200,
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
                    Center(
                      child: ElevatedButton(
                        onPressed: appUrl.isNotEmpty
                            ? () async {
                          if (await canLaunch(appUrl)) {
                            await launch(appUrl);
                          } else {
                            throw 'Could not launch $appUrl';
                          }
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                          minimumSize: Size(MediaQuery.of(context).size.width * 0.8, 36),
                        ),
                        child: Text('Download from Play Store'),
                      ),
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
                        maxLines: 4,
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
                              Image.network(
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
                        onPressed: status == 'Approved' ? () => _claimReward(context) : null,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: claimButtonColor,
                          minimumSize: Size(MediaQuery.of(context).size.width * 0.6, 36),
                        ),
                        child: Text('Claim'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Future<QuerySnapshot> _fetchReviewDetails() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      print('Fetching review details for orderId: $orderId with UID: $uid');
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Reviews')
          .doc(uid)
          .collection('Submissions')
          .where('orderId', isEqualTo: int.parse(orderId)) // Ensure orderId is of the correct type
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print('Review found: ${querySnapshot.docs.first.data()}');
        return querySnapshot;
      } else {
        print('Review not found for orderId: $orderId');
        throw Exception('Review not found');
      }
    } catch (e) {
      print('Error fetching review details: $e');
      throw e;
    }
  }

  void _claimReward(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Congratulations! Reward claimed!')),
    );
  }
}
