import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'dart:io';
import 'photo_service.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static int? _calculateAge(DateTime? birthday) {
    if (birthday == null) return null;
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month || (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }

  static Future<void> createUserProfile({
    required String firstName,
    required String lastName,
    DateTime? birthday,
    String? gender,
    List<String>? interests,
    String? profileImageUrl,
    List<File>? photos,
    String? occupation,
    String? education,
    String? height,
    String? race,
    String? religion,
    String? phoneNumber,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Get phone number from Firebase Auth or provided parameter
    String finalPhoneNumber = phoneNumber ?? user.phoneNumber ?? '';
    
    // If user has multiple providers, check for phone number in any of them
    if (finalPhoneNumber.isEmpty) {
      for (final provider in user.providerData) {
        if (provider.phoneNumber != null && provider.phoneNumber!.isNotEmpty) {
          finalPhoneNumber = provider.phoneNumber!;
          break;
        }
      }
    }

    // Upload photos if provided
    List<String>? photoUrls;
    String? mainPhotoUrl = profileImageUrl;
    
    if (photos != null && photos.isNotEmpty) {
      final nonNullPhotos = photos.where((photo) => photo != null).cast<File>().toList();
      if (nonNullPhotos.isNotEmpty) {
        photoUrls = await PhotoService.uploadMultiplePhotos(nonNullPhotos);
        if (photoUrls.isNotEmpty) {
          mainPhotoUrl = photoUrls.first; // Set first photo as main profile image
        }
      }
    }
    
    // Check existing profile for phone number
    if (finalPhoneNumber.isEmpty) {
      try {
        final existingDoc = await _firestore.collection('users').doc(user.uid).get();
        if (existingDoc.exists && existingDoc.data()?['phoneNumber'] != null) {
          finalPhoneNumber = existingDoc.data()!['phoneNumber'];
        }
      } catch (e) {
        print('Error checking existing profile: $e');
      }
    }

    final userData = {
      'uid': user.uid,
      'phoneNumber': finalPhoneNumber,
      'firstName': firstName,
      'lastName': lastName,
      'birthday': birthday?.millisecondsSinceEpoch,
      'age': _calculateAge(birthday),
      'gender': gender,
      'interests': interests ?? [],
      'profileImageUrl': mainPhotoUrl,
      'photoUrls': photoUrls,
      'occupation': occupation,
      'education': education,
      'height': height,
      'race': race,
      'religion': religion,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    print('Creating user profile for UID: ${user.uid}');
    print('Phone number being saved: $finalPhoneNumber');
    
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(userData, SetOptions(merge: true));
        
    print('User profile created successfully in Firestore');
  }

  static Future<UserModel?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) {
        print('User document does not exist');
        return null;
      }
      
      final data = doc.data()!;
      // Check if this is a complete profile (has required fields)
      if (data['firstName'] == null || data['lastName'] == null) {
        print('User profile incomplete - missing required fields');
        return null;
      }
      
      print('User profile found and complete');
      print('Phone number in profile: ${data['phoneNumber']}');
      return UserModel.fromMap(data);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  static Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    DateTime? birthday,
    String? gender,
    List<String>? interests,
    String? profileImageUrl,
    List<String>? photoUrls,
    String? phoneNumber,
    String? email,
    String? religion,
    String? occupation,
    String? education,
    String? height,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    if (firstName != null) updates['firstName'] = firstName;
    if (lastName != null) updates['lastName'] = lastName;
    if (birthday != null) {
      updates['birthday'] = birthday.millisecondsSinceEpoch;
      updates['age'] = _calculateAge(birthday);
    }
    if (gender != null) updates['gender'] = gender;
    if (interests != null) updates['interests'] = interests;
    if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
    if (photoUrls != null) updates['photoUrls'] = photoUrls;
    if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
    if (email != null) updates['email'] = email;
    if (religion != null) updates['religion'] = religion;
    if (occupation != null) updates['occupation'] = occupation;
    if (education != null) updates['education'] = education;
    if (height != null) updates['height'] = height;

    print('=== UPDATING USER PROFILE ===');
    print('photoUrls: $photoUrls');
    print('profileImageUrl: $profileImageUrl');
    print('Updates: $updates');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .update(updates);
        
    print('Profile updated successfully');
    print('=== END UPDATE ===');
  }

  static Future<void> updatePhoneNumberFromAuth() async {
    final user = _auth.currentUser;
    if (user == null) return;

    String phoneNumber = user.phoneNumber ?? '';
    
    // Check all providers for phone number
    if (phoneNumber.isEmpty) {
      for (final provider in user.providerData) {
        if (provider.phoneNumber != null && provider.phoneNumber!.isNotEmpty) {
          phoneNumber = provider.phoneNumber!;
          break;
        }
      }
    }

    if (phoneNumber.isNotEmpty) {
      // Check if user profile exists, if not create it with phone number
      final existingProfile = await getUserProfile();
      if (existingProfile == null) {
        // Create a minimal profile with phone number
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'phoneNumber': phoneNumber,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      } else {
        await updateUserProfile(phoneNumber: phoneNumber);
      }
      print('Updated user profile with phone number: $phoneNumber');
    }
  }

  static Future<void> forceUpdatePhoneNumber(String phoneNumber) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    await _firestore.collection('users').doc(user.uid).set({
      'phoneNumber': phoneNumber,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
    
    print('Force updated phone number to: $phoneNumber');
  }

  static Future<void> deleteUserAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    try {
      // Delete Firebase Auth account only
      await user.delete();
      print('Firebase Auth account deleted');
    } catch (e) {
      print('Error deleting user account: $e');
      rethrow;
    }
  }
  
  static Future<bool> checkPhoneNumberExists(String phoneNumber) async {
    try {
      if (phoneNumber.trim().isEmpty) {
        return false;
      }
      
      final cleanPhoneNumber = phoneNumber.trim();
      
      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: cleanPhoneNumber)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking phone number: $e');
      throw Exception('Unable to verify phone number. Please check your internet connection.');
    }
  }
}