import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';


import 'CreateUser.dart';

class GettingStartedScreen extends StatefulWidget {
  @override
  _GettingStartedScreenState createState() => _GettingStartedScreenState();
}

class _GettingStartedScreenState extends State<GettingStartedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildPage(
                image: 'assets/NewUser/horse.png',
                title: 'Play Around!',
                description: 'Forget everything you know about the chaotic world of earning. It can be easy.',
                isDarkTheme: isDarkTheme,
              ),
              _buildPage(
                image: 'assets/NewUser/Coins.png',
                title: 'Earn Coins!',
                description: 'Forget everything you know about the chaotic world of earning. It can be easy.',
                isDarkTheme: isDarkTheme,
              ),
              _buildPage(
                image: 'assets/NewUser/Bank.png',
                title: 'Easy Payouts!',
                description: 'Forget everything you know about the chaotic world of earning. It can be easy.',
                isDarkTheme: isDarkTheme,
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SmoothPageIndicator(
                  controller: _pageController,
                  count: 3,
                  effect: WormEffect(
                    dotColor: Colors.grey,
                    activeDotColor: isDarkTheme ? Colors.white : Colors.black,
                    dotHeight: 12,
                    dotWidth: 12,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_forward,
                    color: isDarkTheme ? Colors.white : Colors.black,
                    size: 30,
                  ),
                  onPressed: () {
                    if (_currentPage < 2) {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => CreateUserScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({
    required String image,
    required String title,
    required String description,
    required bool isDarkTheme,
  }) {
    return Container(
      color: isDarkTheme ? Colors.black : Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Image.asset(
              image,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 20), // Add space between image and text
          Text(
            title,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDarkTheme ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.left, // Align title text to the left
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20), // Add padding for description text
            child: Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: isDarkTheme ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.left, // Align description text to the left
            ),
          ),
        ],
      ),
    );
  }
}
