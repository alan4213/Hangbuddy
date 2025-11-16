import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> createMatch({
    required String user1Id,
    required String user2Id,
    required String hangoutTitle,
    required String hangoutLocation,
    required DateTime hangoutDateTime,
  }) async {
    // Check if match already exists for this specific hangout
    final existingMatches = await _firestore
        .collection('matches')
        .where('status', isEqualTo: 'active')
        .where('hangoutTitle', isEqualTo: hangoutTitle)
        .get();
    
    for (final doc in existingMatches.docs) {
      final data = doc.data();
      if ((data['user1Id'] == user1Id && data['user2Id'] == user2Id) ||
          (data['user1Id'] == user2Id && data['user2Id'] == user1Id)) {
        return; // Match already exists for this hangout
      }
    }
    
    final matchId = '${user1Id}_${user2Id}_${DateTime.now().millisecondsSinceEpoch}';
    
    final matchData = {
      'id': matchId,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'hangoutTitle': hangoutTitle,
      'hangoutLocation': hangoutLocation,
      'hangoutDateTime': Timestamp.fromDate(hangoutDateTime),
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'status': 'active',
    };

    await _firestore.collection('matches').doc(matchId).set(matchData);
  }

  static Future<void> deleteMatch(String matchId) async {
    await _firestore.collection('matches').doc(matchId).update({
      'status': 'deleted'
    });
  }

  static Future<void> deleteMatchBetweenUsers(String user1Id, String user2Id) async {
    final matchesSnapshot = await _firestore
        .collection('matches')
        .where('status', isEqualTo: 'active')
        .get();
    
    for (final doc in matchesSnapshot.docs) {
      final data = doc.data();
      if ((data['user1Id'] == user1Id && data['user2Id'] == user2Id) ||
          (data['user1Id'] == user2Id && data['user2Id'] == user1Id)) {
        await doc.reference.update({'status': 'deleted'});
        break;
      }
    }
  }

  static Stream<List<Map<String, dynamic>>> getUserMatches() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('matches')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      print('Matches found: ${snapshot.docs.length}');
      print('Current user for matches: ${user.uid}');
      final userMatches = snapshot.docs
          .where((doc) {
            final data = doc.data();
            print('Match data: $data');
            final isUserMatch = data['user1Id'] == user.uid || data['user2Id'] == user.uid;
            print('Is user match: $isUserMatch');
            return isUserMatch;
          })
          .map((doc) => doc.data())
          .toList();
      print('User matches: ${userMatches.length}');
      return userMatches;
    });
  }
}