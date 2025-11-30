import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountManager {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Check if an email already has an account
  static Future<bool> emailExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      print('Error checking email existence: $e');
      return false;
    }
  }
  
  /// Check if a phone number already has an account
  static Future<DocumentSnapshot?> phoneExists(String phoneNumber) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty ? query.docs.first : null;
    } catch (e) {
      print('Error checking phone existence: $e');
      return null;
    }
  }
  
  /// Find accounts that might be duplicates
  static Future<List<DocumentSnapshot>> findPotentialDuplicates(String? email, String? phoneNumber) async {
    try {
      final List<DocumentSnapshot> duplicates = [];
      
      if (email != null) {
        final emailQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .get();
        duplicates.addAll(emailQuery.docs);
      }
      
      if (phoneNumber != null) {
        final phoneQuery = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: phoneNumber)
            .get();
        duplicates.addAll(phoneQuery.docs);
      }
      
      // Remove duplicates from the list
      final Map<String, DocumentSnapshot> uniqueDocs = {};
      for (final doc in duplicates) {
        uniqueDocs[doc.id] = doc;
      }
      
      return uniqueDocs.values.toList();
    } catch (e) {
      print('Error finding duplicates: $e');
      return [];
    }
  }
  
  /// Merge two user accounts
  static Future<bool> mergeAccounts({
    required String primaryUid,
    required String secondaryUid,
    String? phoneNumber,
    String? email,
  }) async {
    try {
      print('Merging accounts: $secondaryUid -> $primaryUid');
      
      // Get data from both accounts
      final primaryDoc = await _firestore.collection('users').doc(primaryUid).get();
      final secondaryDoc = await _firestore.collection('users').doc(secondaryUid).get();
      
      final primaryData = primaryDoc.data() ?? {};
      final secondaryData = secondaryDoc.data() ?? {};
      
      // Merge the data (primary takes precedence, but fill in missing fields)
      final mergedData = {
        ...secondaryData,
        ...primaryData,
        'uid': primaryUid,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Add phone and email if provided
      if (phoneNumber != null) mergedData['phoneNumber'] = phoneNumber;
      if (email != null) mergedData['email'] = email;
      
      // Update primary account with merged data
      await _firestore.collection('users').doc(primaryUid).set(mergedData, SetOptions(merge: true));
      
      // Delete secondary account
      await _firestore.collection('users').doc(secondaryUid).delete();
      
      print('Successfully merged accounts');
      return true;
    } catch (e) {
      print('Error merging accounts: $e');
      return false;
    }
  }
  
  /// Clean up orphaned accounts
  static Future<void> cleanupOrphanedAccounts() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      // Find all user documents that don't match the current user
      final query = await _firestore
          .collection('users')
          .where('uid', isNotEqualTo: currentUser.uid)
          .get();
      
      for (final doc in query.docs) {
        final data = doc.data();
        final email = data['email'] as String?;
        final phone = data['phoneNumber'] as String?;
        
        // Check if this account matches current user's email or phone
        bool shouldDelete = false;
        
        if (email != null && email == currentUser.email) {
          shouldDelete = true;
        }
        
        if (phone != null && phone == currentUser.phoneNumber) {
          shouldDelete = true;
        }
        
        if (shouldDelete) {
          await doc.reference.delete();
          print('Cleaned up orphaned account: ${doc.id}');
        }
      }
    } catch (e) {
      print('Error cleaning up orphaned accounts: $e');
    }
  }
  
  /// Prevent duplicate account creation
  static Future<String?> checkAndPreventDuplicates({
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final duplicates = await findPotentialDuplicates(email, phoneNumber);
      
      if (duplicates.isNotEmpty) {
        // Return the UID of the existing account
        return duplicates.first.id;
      }
      
      return null; // No duplicates found
    } catch (e) {
      print('Error checking for duplicates: $e');
      return null;
    }
  }
}