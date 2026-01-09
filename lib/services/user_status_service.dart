import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserStatusService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<bool> isUserBanned(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final status = userDoc.data()?['status'];
        return status == 'banned';
      }
      return false;
    } catch (e) {
      print('Error checking user status: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getUserStatus(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        return {
          'status': data['status'],
          'bannedAt': data['bannedAt'],
          'warningCount': data['warningCount'] ?? 0,
          'lastWarningAt': data['lastWarningAt'],
        };
      }
      return null;
    } catch (e) {
      print('Error getting user status: $e');
      return null;
    }
  }

  static Future<void> signOutBannedUser() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Error signing out banned user: $e');
    }
  }
}