import 'package:flutter/material.dart';

class InfoReview extends StatelessWidget {
  final String orderId;

  InfoReview({required this.orderId});

  @override
  Widget build(BuildContext context) {
    // Replace this with your desired UI for showing review information
    return Scaffold(
      appBar: AppBar(
        title: Text('Review Info'),
      ),
      body: Center(
        child: Text('Review Information for order ID: $orderId'),
      ),
    );
  }
}
