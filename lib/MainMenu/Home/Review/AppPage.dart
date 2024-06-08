import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../AppClass.dart';
import 'SubmitReview.dart';

class AppPage extends StatelessWidget {
  final Game game;

  AppPage({required this.game});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'App Details',
          style: theme.appBarTheme.titleTextStyle,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.all(5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  game.imagePath,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
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
                          color: theme.textTheme.headlineSmall?.color,
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
                              color: theme.textTheme.headlineSmall?.color,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'per Review',
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              game.name,
              style: TextStyle(color: theme.textTheme.headlineSmall?.color, fontSize: 24),
            ),
            SizedBox(height: 8),
            Text(
              game.description,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SubmitReviewScreen(
                          orderId: game.orderId,
                          appName: game.name,
                          appURL: game.appURL,
                          appImageURL: game.imagePath,
                        )),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: isDarkMode ? Colors.black : Colors.white, backgroundColor: isDarkMode ? Colors.white : Colors.black,
                    ),
                    child: Text('Submit Proof'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      launchURL(game.appURL);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: isDarkMode ? Colors.white : Colors.black, backgroundColor: isDarkMode ? Colors.black : Colors.white,
                      side: BorderSide(color: isDarkMode ? Colors.white : Colors.black),
                    ),
                    child: Text('Download App'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
