import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

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
      'hangoutStatus': 'active',
    };

    await _firestore.collection('matches').doc(matchId).set(matchData);
    
    // Send match notifications to both users
    await _sendMatchNotification(user2Id, user1Id, hangoutTitle);
    await _sendMatchNotification(user1Id, user2Id, hangoutTitle);
  }
  
  static Future<void> _sendMatchNotification(String userId, String matchedUserId, String hangoutTitle) async {
    try {
      // Create single notification in Firestore
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'match',
        'message': 'It\'s a Match! You matched for "$hangoutTitle"',
        'matchedUserId': matchedUserId,
        'hangoutTitle': hangoutTitle,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
      
      // Get matched user's name and send single push notification
      final matchedUserDoc = await _firestore.collection('users').doc(matchedUserId).get();
      final matchedUserName = matchedUserDoc.exists 
          ? '${matchedUserDoc.data()?['firstName'] ?? ''} ${matchedUserDoc.data()?['lastName'] ?? ''}'.trim()
          : 'Someone';
      
      await NotificationService.sendMatchNotification(userId, matchedUserName.isEmpty ? 'Someone' : matchedUserName);
    } catch (e) {
      print('Error sending match notification: $e');
    }
  }

  static Future<void> markHangoutAsDeleted(String hangoutTitle) async {
    final matchesSnapshot = await _firestore
        .collection('matches')
        .where('hangoutTitle', isEqualTo: hangoutTitle)
        .where('status', isEqualTo: 'active')
        .get();
    
    for (final doc in matchesSnapshot.docs) {
      await doc.reference.update({'hangoutStatus': 'deleted'});
    }
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