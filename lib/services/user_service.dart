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
    
    // Register phone number in separate collection for duplicate checking
    if (finalPhoneNumber.isNotEmpty) {
      await registerPhoneNumber(finalPhoneNumber);
    }
  }

  static UserModel? _cachedProfile;
  static UserModel? get cachedProfile => _cachedProfile;

  static void clearCache() {
    _cachedProfile = null;
  }

  static Future<UserModel?> getUserProfile({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    if (!forceRefresh && _cachedProfile != null && _cachedProfile!.uid == user.uid) {
      return _cachedProfile;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) {
        print('User document does not exist');
        return null;
      }
      
      final data = doc.data()!;
      
      // Check if account is deleted
      if (data['isDeleted'] == true) {
        print('User account is deleted');
        return null;
      }
      
      // Check if this is a complete profile (has required fields)
      if (data['firstName'] == null || data['lastName'] == null) {
        print('User profile incomplete - missing required fields');
        return null;
      }
      
      print('User profile found and complete');
      print('Phone number in profile: ${data['phoneNumber']}');
      _cachedProfile = UserModel.fromMap(data);
      return _cachedProfile;
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
        
    _cachedProfile = null;
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
      // Get user's phone number before deletion
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final phoneNumber = userDoc.data()?['phoneNumber'] as String?;
      
      // Soft delete user document in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'isDeleted': true,
        'deletedAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Delete all active hangout requests created by this user
      final hangoutRequests = await _firestore
          .collection('hangout_requests')
          .where('creatorId', isEqualTo: user.uid)
          .get();
          
      for (final doc in hangoutRequests.docs) {
        await doc.reference.delete();
      }
      
      print('Deleted ${hangoutRequests.docs.length} active hangout requests');
      
      // IMMEDIATELY free up the phone number for reuse
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        final encodedPhone = _encodePhoneNumber(phoneNumber);
        await _firestore.collection('phone_numbers').doc(encodedPhone).delete();
        print('Phone number freed for reuse: $phoneNumber');
      }
      
      // Hard delete from Firebase Authentication (no recovery)
      await user.delete();
      print('User account permanently deleted from authentication and soft-deleted from database');
    } catch (e) {
      if (e.toString().contains('requires-recent-login')) {
        throw Exception('REAUTH_REQUIRED');
      }
      print('Error deleting user account: $e');
      rethrow;
    }
  }

  static Future<void> reauthenticateWithPhone(String verificationId, String smsCode) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    
    await user.reauthenticateWithCredential(credential);
  }

  // Method to permanently delete user data (run by admin/cron job after 30 days)
  static Future<void> permanentlyDeleteUser(String uid, String phoneNumber) async {
    try {
      // Delete phone number from phone_numbers collection
      if (phoneNumber.isNotEmpty) {
        final encodedPhone = _encodePhoneNumber(phoneNumber);
        await _firestore.collection('phone_numbers').doc(encodedPhone).delete();
        print('Phone number freed: $phoneNumber');
      }
      
      // Delete user document from Firestore
      await _firestore.collection('users').doc(uid).delete();
      print('User permanently deleted: $uid');
    } catch (e) {
      print('Error permanently deleting user: $e');
      rethrow;
    }
  }
  
  static String _encodePhoneNumber(String phoneNumber) {
    // Replace + with 'plus' and other special characters
    return phoneNumber.replaceAll('+', 'plus').replaceAll('-', 'dash');
  }

  static Future<bool> checkPhoneNumberExists(String phoneNumber) async {
    try {
      final cleanPhoneNumber = phoneNumber.trim();
      final encodedPhone = _encodePhoneNumber(cleanPhoneNumber);
      print('=== CHECKING PHONE NUMBER EXISTS ===');
      print('Original phone: $cleanPhoneNumber');
      print('Encoded phone: $encodedPhone');
      
      final doc = await _firestore.collection('phone_numbers').doc(encodedPhone).get();
      
      print('Document exists: ${doc.exists}');
      if (doc.exists) {
        print('Document data: ${doc.data()}');
      }
      
      return doc.exists;
    } catch (e) {
      print('=== ERROR CHECKING PHONE NUMBER ===');
      print('Error: $e');
      throw Exception('Unable to verify phone number. Please check your internet connection.');
    }
  }

  static Future<void> registerPhoneNumber(String phoneNumber) async {
    try {
      final cleanPhoneNumber = phoneNumber.trim();
      final encodedPhone = _encodePhoneNumber(cleanPhoneNumber);
      print('=== REGISTERING PHONE NUMBER ===');
      print('Original phone: $cleanPhoneNumber');
      print('Encoded phone: $encodedPhone');
      
      await _firestore.collection('phone_numbers').doc(encodedPhone).set({
        'originalPhone': cleanPhoneNumber,
        'exists': true,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      print('Phone number registration completed successfully');
    } catch (e) {
      print('=== ERROR REGISTERING PHONE NUMBER ===');
      print('Error: $e');
      rethrow;
    }
  }

  static Future<void> migrateExistingPhoneNumbers() async {
    try {
      print('=== STARTING PHONE NUMBER MIGRATION ===');
      final usersSnapshot = await _firestore.collection('users').get();
      print('Found ${usersSnapshot.docs.length} user documents');
      
      int migratedCount = 0;
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final phoneNumber = data['phoneNumber'] as String?;
        
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          print('Migrating phone: $phoneNumber for user: ${doc.id}');
          await registerPhoneNumber(phoneNumber);
          migratedCount++;
        } else {
          print('Skipping user ${doc.id} - no phone number');
        }
      }
      
      print('=== MIGRATION COMPLETED: $migratedCount phones migrated ===');
    } catch (e) {
      print('=== MIGRATION ERROR: $e ===');
      rethrow;
    }
  }

  static Future<bool> checkEmailExists(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      print('=== CHECKING EMAIL EXISTS ===');
      print('Email: $cleanEmail');
      
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .get();
      
      // Filter out deleted accounts in code instead of query
      final activeUsers = querySnapshot.docs.where((doc) => doc.data()['isDeleted'] != true).toList();
      final exists = activeUsers.isNotEmpty;
      
      print('Email exists: $exists');
      
      if (exists) {
        final existingUser = activeUsers.first.data();
        print('Email linked to phone: ${existingUser['phoneNumber']}');
      }
      
      return exists;
    } catch (e) {
      print('Error checking email: $e');
      throw Exception('Unable to verify email. Please check your internet connection.');
    }
  }
  static Future<void> checkPhoneNumbersCollection() async {
    try {
      print('=== CHECKING PHONE_NUMBERS COLLECTION ===');
      final snapshot = await _firestore.collection('phone_numbers').limit(5).get();
      print('Collection exists: ${snapshot.docs.isNotEmpty}');
      print('Document count (first 5): ${snapshot.docs.length}');
      
      for (var doc in snapshot.docs) {
        print('  - Phone: ${doc.id}');
        print('  - Data: ${doc.data()}');
      }
      
      if (snapshot.docs.isEmpty) {
        print('Collection is empty - migration may not have run');
      }
    } catch (e) {
      print('Error checking collection: $e');
    }
  }

  // Method to clean up expired phone numbers (run by scheduled function/cron job)
  static Future<void> cleanupExpiredPhoneNumbers() async {
    try {
      print('=== STARTING PHONE NUMBER CLEANUP ===');
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final snapshot = await _firestore
          .collection('phone_numbers')
          .where('markedForDeletion', isEqualTo: true)
          .where('deletionScheduledAt', isLessThanOrEqualTo: now)
          .get();
      
      print('Found ${snapshot.docs.length} expired phone numbers to clean up');
      
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
        print('Cleaned up phone number: ${doc.data()['originalPhone']}');
      }
      
      print('=== PHONE NUMBER CLEANUP COMPLETED ===');
    } catch (e) {
      print('Error during phone number cleanup: $e');
      rethrow;
    }
  }
}