import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../MainMenu.dart';

class SubmitReviewScreen extends StatefulWidget {
  final int orderId;
  final String appName;
  final String appURL;
  final String appImageURL;

  SubmitReviewScreen({
    required this.orderId,
    required this.appName,
    required this.appURL,
    required this.appImageURL,
  });

  @override
  _SubmitReviewScreenState createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends State<SubmitReviewScreen> {
  final ImagePicker _picker = ImagePicker();
  List<File?> _pickedImages = [null, null, null];
  List<double> _uploadProgress = [0, 0, 0];
  TextEditingController _reviewController = TextEditingController();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Submit Review',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          color: isDarkMode ? Colors.black : Colors.white,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _reviewController,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'Write Same Review You Submitted',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDarkMode ? Colors.white : Colors.black),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(3, (index) {
                  return GestureDetector(
                    onTap: () async {
                      File? image = await _pickImage();
                      if (image != null) {
                        setState(() {
                          _pickedImages[index] = image;
                          _uploadProgress[index] = 0;
                        });
                      }
                    },
                    child: Container(
                      width: (size.width - 60) / 3,
                      height: 100,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black : Colors.white,
                        border: Border.all(color: isDarkMode ? Colors.white : Colors.black),
                      ),
                      child: _pickedImages[index] != null
                          ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_pickedImages[index]!, fit: BoxFit.cover),
                          if (_isUploading)
                            Center(
                              child: CircularProgressIndicator(
                                value: _uploadProgress[index] / 100,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    isDarkMode ? Colors.white : Colors.black),
                              ),
                            ),
                        ],
                      )
                          : Center(
                        child: Icon(
                          Icons.add,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: isDarkMode ? Colors.white : Colors.black,
                    backgroundColor: isDarkMode ? Colors.white : Colors.black,
                  ),
                  child: _isUploading
                      ? CircularProgressIndicator()
                      : Text(
                    'Submit Review',
                    style: TextStyle(color: isDarkMode ? Colors.black : Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<File?> _pickImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      return File(pickedImage.path);
    }
    return null;
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please write a review')),
      );
      return;
    }
    if (_pickedImages.every((image) => image == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }
    setState(() {
      _isUploading = true;
    });

    try {
      // Upload images to Firebase Storage and get URLs
      List<String> imageUrls = await _uploadImages();

      // Save review details to Firestore
      String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('Reviews').doc(uid).collection('Submissions').add({
        'review': _reviewController.text,
        'images': imageUrls,
        'timestamp': FieldValue.serverTimestamp(),
        'orderId': widget.orderId,
        'ReviewStatus': 'In Review',
        'appName': widget.appName,
        'appURL': widget.appURL,
        'appImageURL': widget.appImageURL,
        'claimed': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        customSubmissionSnackbar(
          message: 'Submission Submitted\nWe will review your proof and you will receive coins shortly.',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainMenu()),
            );
          },
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: $error')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];

    for (int i = 0; i < _pickedImages.length; i++) {
      if (_pickedImages[i] != null) {
        File image = _pickedImages[i]!;
        String imageName = 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        Reference ref = FirebaseStorage.instance.ref().child('ReviewDocuments/$imageName');
        UploadTask uploadTask = ref.putFile(image);

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          setState(() {
            _uploadProgress[i] = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          });
        });

        TaskSnapshot snapshot = await uploadTask;
        String imageUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(imageUrl);
      }
    }
    return imageUrls;
  }

  SnackBar customSubmissionSnackbar({required String message, required VoidCallback onPressed}) {
    return SnackBar(
      content: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
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
                  minimumSize: Size(double.infinity, 36),
                ),
                child: Text(
                  'Back to Home',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.grey[850],
    );
  }
}
