import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static Future<String?> getVerificationStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data()?['verificationStatus'];
      }
      return null;
    } catch (e) {
      print('Error getting verification status: $e');
      return null;
    }
  }
  
  static Future<bool> isVerified() async {
    final status = await getVerificationStatus();
    return status == 'verified';
  }
  
  static Future<bool> isPending() async {
    final status = await getVerificationStatus();
    return status == 'pending';
  }
}