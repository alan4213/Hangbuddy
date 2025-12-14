import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class PhotoVerificationScreen extends StatefulWidget {
  const PhotoVerificationScreen({super.key});

  @override
  State<PhotoVerificationScreen> createState() => _PhotoVerificationScreenState();
}

class _PhotoVerificationScreenState extends State<PhotoVerificationScreen> {
  int _currentStep = 0;
  File? _capturedPhoto1;
  File? _capturedPhoto2;
  bool _isUploading = false;

  final List<String> _poseImages = [
    'assets/images/verification1.jpg',
    'assets/images/verification2.jpg',
  ];

  final List<String> _poseInstructions = [
    'Hold your phone at eye level and look directly at the camera',
    'Turn your head slightly to the right while looking at the camera',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Photo Verification',
          style: TextStyle(
            color: Colors.black,
            fontSize: Responsive.fontSize(context, Responsive.headingFontSize),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Responsive.padding(context, Responsive.mediumPadding)),
          child: Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: (_currentStep + 1) / 3,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
              
              SizedBox(height: Responsive.padding(context, 0.04)),
              
              // Step indicator
              Text(
                'Step ${_currentStep + 1} of 2',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, Responsive.bodyFontSize),
                  color: Colors.grey[600],
                ),
              ),
              
              SizedBox(height: Responsive.padding(context, 0.06)),
              
              Expanded(
                child: _currentStep < 2 ? _buildPoseStep() : _buildReviewStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoseStep() {
    return Column(
      children: [
        // Pose image
        Container(
          height: MediaQuery.of(context).size.height * 0.3,
          width: MediaQuery.of(context).size.width * 0.6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              _poseImages[_currentStep],
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        SizedBox(height: Responsive.padding(context, 0.04)),
        
        // Instructions
        Text(
          'Copy this pose',
          style: TextStyle(
            fontSize: Responsive.fontSize(context, Responsive.headingFontSize),
            fontWeight: FontWeight.bold,
          ),
        ),
        
        SizedBox(height: Responsive.padding(context, 0.02)),
        
        Text(
          _poseInstructions[_currentStep],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, Responsive.bodyFontSize),
            color: Colors.grey[600],
          ),
        ),
        
        const Spacer(),
        
        // Camera button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            onPressed: _takePhoto,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Take Photo',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, Responsive.bodyFontSize),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      children: [
        Text(
          'Review Your Photos',
          style: TextStyle(
            fontSize: Responsive.fontSize(context, Responsive.headingFontSize),
            fontWeight: FontWeight.bold,
          ),
        ),
        
        SizedBox(height: Responsive.padding(context, 0.04)),
        
        // Photo previews
        Row(
          children: [
            Expanded(
              child: _buildPhotoPreview(_capturedPhoto1, 'Pose 1'),
            ),
            SizedBox(width: Responsive.padding(context, 0.04)),
            Expanded(
              child: _buildPhotoPreview(_capturedPhoto2, 'Pose 2'),
            ),
          ],
        ),
        
        SizedBox(height: Responsive.padding(context, 0.04)),
        
        Text(
          'Your photos will be reviewed within 24 hours. You\'ll receive a notification once verified.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, Responsive.bodyFontSize),
            color: Colors.grey[600],
          ),
        ),
        
        const Spacer(),
        
        // Submit button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            onPressed: _isUploading ? null : _submitVerification,
            child: _isUploading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Submit for Review',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, Responsive.bodyFontSize),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPreview(File? photo, String label) {
    return Column(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: photo != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(photo, fit: BoxFit.cover),
                )
              : const Icon(Icons.photo, size: 50, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, Responsive.smallFontSize),
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
      );
      
      if (photo != null) {
        setState(() {
          if (_currentStep == 0) {
            _capturedPhoto1 = File(photo.path);
          } else {
            _capturedPhoto2 = File(photo.path);
          }
          _currentStep++;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submitVerification() async {
    setState(() => _isUploading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      
      // Upload photos to Firebase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final ref1 = FirebaseStorage.instance
          .ref()
          .child('verification_photos')
          .child('${user.uid}_pose1_$timestamp.jpg');
      
      final ref2 = FirebaseStorage.instance
          .ref()
          .child('verification_photos')
          .child('${user.uid}_pose2_$timestamp.jpg');
      
      await ref1.putFile(_capturedPhoto1!);
      await ref2.putFile(_capturedPhoto2!);
      
      final photo1Url = await ref1.getDownloadURL();
      final photo2Url = await ref2.getDownloadURL();
      
      // Create verification request in Firestore
      await FirebaseFirestore.instance
          .collection('verification_requests')
          .doc(user.uid)
          .set({
        'userId': user.uid,
        'pose1PhotoUrl': photo1Url,
        'pose2PhotoUrl': photo2Url,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': null,
      });
      
      // Update user verification status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'verificationStatus': 'pending',
        'verificationSubmittedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification submitted! You\'ll hear back within 24 hours.'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting verification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }
}