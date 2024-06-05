import 'package:flutter/material.dart';

SnackBar customPasswordSnackbar({required String message, required VoidCallback onPressed}) {
  return SnackBar(
    content: Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15.0), // Adjust the radius as needed
            child: Image.asset(
              'assets/ExclaimationMark.png',
              width: 50,
              height: 50,
            ),
          ),
          SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white),
                ),
                minimumSize: Size(double.infinity, 36), // Ensure button stretches to full width
              ),
              child: Text(
                'Back to Login',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    ),
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.grey[850],  // Light black/grey color

  );
}
