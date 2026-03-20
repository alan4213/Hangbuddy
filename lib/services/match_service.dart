import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class MatchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final Set<String> _pendingMatches = {};

  static Future<void> createMatch({
    required String user1Id,
    required String user2Id,
    required String hangoutTitle,
    required String hangoutLocation,
    required DateTime hangoutDateTime,
    String? hangoutCategory,
  }) async {
    print('🔄 MatchService.createMatch called:');
    print('   user1Id: $user1Id');
    print('   user2Id: $user2Id');
    print('   hangoutTitle: $hangoutTitle');
    
    // Create unique key for this match request
    final matchKey = '${user1Id}_${user2Id}_$hangoutTitle';
    
    // Check if this exact match is already being processed
    if (_pendingMatches.contains(matchKey)) {
      print('⚠️ Match request already in progress for $matchKey');
      return;
    }
    
    // Add to pending set
    _pendingMatches.add(matchKey);
    print('✅ Added to pending matches: $matchKey');
    
    try {
      // If category is not provided, try to fetch it from the original hangout
      if (hangoutCategory == null) {
        print('🔍 Fetching hangout category...');
        try {
          final hangoutQuery = await _firestore
              .collection('hangout_requests')
              .where('title', isEqualTo: hangoutTitle)
              .where('status', isEqualTo: 'active')
              .limit(1)
              .get();
          
          if (hangoutQuery.docs.isNotEmpty) {
            hangoutCategory = hangoutQuery.docs.first.data()['category'] ?? 'Other';
            print('✅ Found hangout category: $hangoutCategory');
          } else {
            print('⚠️ No hangout found with title: $hangoutTitle');
          }
        } catch (e) {
          print('❌ Error fetching hangout category: $e');
          hangoutCategory = 'Other';
        }
      }
      
      // Create deterministic match ID to prevent duplicates
      final sortedIds = [user1Id, user2Id]..sort();
      final matchId = '${sortedIds[0]}_${sortedIds[1]}_${hangoutTitle.replaceAll(' ', '_')}';
      print('🎯 Generated match ID: $matchId');
      
      final matchData = {
        'id': matchId,
        'user1Id': user1Id,
        'user2Id': user2Id,
        'hangoutTitle': hangoutTitle,
        'hangoutLocation': hangoutLocation,
        'hangoutDateTime': Timestamp.fromDate(hangoutDateTime),
        'hangoutCategory': hangoutCategory ?? 'Other',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'status': 'active',
        'hangoutStatus': 'active',
      };
      
      print('💾 Attempting to save match document...');
      print('   Match data: $matchData');

      // Use set() with merge: false to prevent duplicates
      await _firestore.collection('matches').doc(matchId).set(matchData);
      print('✅ MATCH DOCUMENT SAVED SUCCESSFULLY: $matchId');
      
      // Verify the document was created
      final verifyDoc = await _firestore.collection('matches').doc(matchId).get();
      if (verifyDoc.exists) {
        print('✅ MATCH DOCUMENT VERIFIED IN FIRESTORE');
      } else {
        print('❌ MATCH DOCUMENT NOT FOUND AFTER CREATION!');
      }
      
      print('📧 Sending match notifications...');
      // Send match notifications to both users
      await _sendMatchNotification(user2Id, user1Id, hangoutTitle);
      await _sendMatchNotification(user1Id, user2Id, hangoutTitle);
      print('✅ Match notifications sent');
      
    } catch (e) {
      print('❌ Error creating match: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Error details: ${e.toString()}');
      
      // If it's a document already exists error, that's fine
      if (!e.toString().contains('already exists')) {
        rethrow;
      } else {
        print('✅ Match already exists, continuing...');
      }
    } finally {
      _pendingMatches.remove(matchKey);
      print('🗑️ Removed from pending matches: $matchKey');
    }
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
    print('🔄 Attempting to delete match: $matchId');
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('❌ No current user found');
      throw Exception('No authenticated user');
    }
    
    print('   Current user: ${currentUser.uid}');
    
    try {
      // First, get the match document to verify permissions
      final matchDoc = await _firestore.collection('matches').doc(matchId).get();
      if (!matchDoc.exists) {
        print('❌ Match document does not exist: $matchId');
        throw Exception('Match not found');
      }
      
      final matchData = matchDoc.data()!;
      print('   Match data: $matchData');
      print('   User1Id: ${matchData['user1Id']}');
      print('   User2Id: ${matchData['user2Id']}');
      print('   Current user is participant: ${[matchData['user1Id'], matchData['user2Id']].contains(currentUser.uid)}');
      
      // Delete the match document
      await _firestore.collection('matches').doc(matchId).delete();
      print('✅ Match deleted successfully: $matchId');
    } catch (e) {
      print('❌ Error deleting match: $e');
      print('   Error type: ${e.runtimeType}');
      rethrow;
    }
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
            final isDeleted = data['deletedFor_${user.uid}'] == true;
            print('Is user match: $isUserMatch, Is deleted: $isDeleted');
            return isUserMatch && !isDeleted;
          })
          .map((doc) => doc.data())
          .toList();
      print('User matches: ${userMatches.length}');
      return userMatches;
    });
  }
}