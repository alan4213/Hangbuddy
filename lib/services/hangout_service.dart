import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/hangout_request_model.dart';
import 'location_service.dart';

class HangoutService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> createHangoutRequest({
    required String title,
    required String category,
    required DateTime dateTime,
    required String location,
    double? latitude,
    double? longitude,
    double maxDistance = 30.0,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Check if user already has an active hangout
    final existingHangouts = await _firestore
        .collection('hangout_requests')
        .where('creatorId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'active')
        .get();
    
    if (existingHangouts.docs.isNotEmpty) {
      throw Exception('You already have an active hangout. Please delete it first to create a new one.');
    }

    final docRef = _firestore.collection('hangout_requests').doc();
    
    final hangoutRequest = HangoutRequest(
      id: docRef.id,
      creatorId: user.uid,
      title: title,
      category: category,
      dateTime: dateTime,
      location: location,
      latitude: latitude,
      longitude: longitude,
      maxDistance: maxDistance,
      status: 'active',
      createdAt: DateTime.now(),
    );

    await docRef.set(hangoutRequest.toMap());
  }

  static Stream<List<HangoutRequest>> getActiveHangoutRequests({double? userLatitude, double? userLongitude, double maxDistanceFilter = 40.0}) {
    final user = _auth.currentUser;
    if (user == null || userLatitude == null || userLongitude == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('hangout_requests')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      final filteredHangouts = <HangoutRequest>[];
      
      for (final doc in snapshot.docs) {
        final hangout = HangoutRequest.fromMap(doc.data(), doc.id);
        
        // Skip own hangouts and already viewed hangouts
        if (hangout.creatorId == user.uid || hangout.viewedByUsers.contains(user.uid)) {
          continue;
        }
        
        // Only include hangouts that have location data
        if (hangout.latitude != null && hangout.longitude != null) {
          final distance = LocationService.calculateDistance(
            userLatitude, userLongitude,
            hangout.latitude!, hangout.longitude!
          );
          
          // Only show if within BOTH the user's search range AND the hangout's visibility range
          if (distance <= maxDistanceFilter && distance <= hangout.maxDistance) {
            filteredHangouts.add(hangout);
          }
        }
      }
      
      filteredHangouts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filteredHangouts;
    });
  }

  static Future<void> expressInterest(String hangoutId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    await _firestore.collection('hangout_requests').doc(hangoutId).update({
      'interestedUsers': FieldValue.arrayUnion([user.uid])
    });
  }

  static Future<void> removeInterest(String hangoutId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    await _firestore.collection('hangout_requests').doc(hangoutId).update({
      'interestedUsers': FieldValue.arrayRemove([user.uid])
    });
  }

  static Stream<List<HangoutRequest>> getUserHangouts() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('hangout_requests')
        .where('creatorId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      final hangouts = snapshot.docs
          .map((doc) => HangoutRequest.fromMap(doc.data(), doc.id))
          .toList();
      hangouts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return hangouts;
    });
  }

  static Future<void> deleteHangout(String hangoutId) async {
    await _firestore.collection('hangout_requests').doc(hangoutId).delete();
  }

  static Future<void> acceptUser(String hangoutId, String userId) async {
    await _firestore.collection('hangout_requests').doc(hangoutId).update({
      'interestedUsers': FieldValue.arrayRemove([userId])
    });
  }
  
  static Future<void> acceptUserAndDeleteHangout(String hangoutId) async {
    await _firestore.collection('hangout_requests').doc(hangoutId).delete();
  }

  static Future<void> markAsViewed(String hangoutId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    await _firestore.collection('hangout_requests').doc(hangoutId).update({
      'viewedByUsers': FieldValue.arrayUnion([user.uid])
    });
  }
}