import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> reportUser({
    required String reportedUserId,
    required String reason,
    required String description,
    String? chatId,
    List<String>? messageIds,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      // Create report document
      await _firestore.collection('reports').add({
        'reporterId': currentUser.uid,
        'reportedUserId': reportedUserId,
        'reason': reason,
        'description': description,
        'chatId': chatId,
        'messageIds': messageIds ?? [],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': null,
        'action': null,
      });

      print('Report submitted successfully');
    } catch (e) {
      print('Error submitting report: $e');
      throw e;
    }
  }

  static Future<List<Map<String, dynamic>>> getReports() async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting reports: $e');
      return [];
    }
  }
}