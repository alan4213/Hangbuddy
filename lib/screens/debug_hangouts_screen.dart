import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/hangout_service.dart';
import '../models/hangout_request_model.dart';

class DebugHangoutsScreen extends StatefulWidget {
  const DebugHangoutsScreen({super.key});

  @override
  State<DebugHangoutsScreen> createState() => _DebugHangoutsScreenState();
}

class _DebugHangoutsScreenState extends State<DebugHangoutsScreen> {
  List<String> _debugLogs = [];
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _debugLogs.add('${DateTime.now().toIso8601String()}: $message');
    });
    print(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Hangouts'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _checkUserHangouts,
                    child: const Text('Check My Hangouts'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createTestHangout,
                    child: const Text('Create Test Hangout'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _clearLogs,
                    child: const Text('Clear Logs'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _checkFirestoreConnection,
                    child: const Text('Test Firestore'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Debug Logs:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._debugLogs.map((log) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          log,
                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearLogs() {
    setState(() {
      _debugLogs.clear();
    });
  }

  void _checkUserHangouts() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _addLog('ERROR: No authenticated user');
        return;
      }

      _addLog('Checking hangouts for user: ${user.uid}');
      _addLog('User email: ${user.email}');

      // Check all hangouts for this user
      final allHangouts = await FirebaseFirestore.instance
          .collection('hangout_requests')
          .where('creatorId', isEqualTo: user.uid)
          .get();

      _addLog('Found ${allHangouts.docs.length} total hangouts');

      for (final doc in allHangouts.docs) {
        final data = doc.data();
        _addLog('Hangout ${doc.id}:');
        _addLog('  Title: ${data['title']}');
        _addLog('  Status: ${data['status']}');
        _addLog('  Created: ${data['createdAt']}');
        _addLog('  Category: ${data['category']}');
        _addLog('  Location: ${data['location']}');
      }

      // Check active hangouts specifically
      final activeHangouts = await FirebaseFirestore.instance
          .collection('hangout_requests')
          .where('creatorId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .get();

      _addLog('Found ${activeHangouts.docs.length} active hangouts');

      // Test the stream
      _addLog('Testing getUserHangouts stream...');
      final stream = HangoutService.getUserHangouts();
      final streamData = await stream.first;
      _addLog('Stream returned ${streamData.length} hangouts');

    } catch (e) {
      _addLog('ERROR: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _createTestHangout() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _addLog('ERROR: No authenticated user');
        return;
      }

      _addLog('Creating test hangout...');

      await HangoutService.createHangoutRequest(
        title: 'Test Hangout ${DateTime.now().millisecondsSinceEpoch}',
        category: 'Food & Drink',
        dateTime: DateTime.now().add(const Duration(hours: 2)),
        location: 'Test Location',
        latitude: 37.7749,
        longitude: -122.4194,
        maxDistance: 20.0,
      );

      _addLog('Test hangout created successfully!');
      
      // Wait a moment then check hangouts
      await Future.delayed(const Duration(seconds: 1));
      _checkUserHangouts();

    } catch (e) {
      _addLog('ERROR creating hangout: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _checkFirestoreConnection() async {
    setState(() => _isLoading = true);
    
    try {
      _addLog('Testing Firestore connection...');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _addLog('ERROR: No authenticated user');
        return;
      }

      _addLog('User authenticated: ${user.uid}');
      _addLog('User email: ${user.email}');

      // Test basic Firestore read
      final testDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (testDoc.exists) {
        _addLog('User document exists in Firestore');
        final userData = testDoc.data();
        _addLog('User name: ${userData?['firstName']} ${userData?['lastName']}');
      } else {
        _addLog('WARNING: User document does not exist in Firestore');
      }

      // Test hangout_requests collection access
      final hangoutCollection = await FirebaseFirestore.instance
          .collection('hangout_requests')
          .limit(1)
          .get();

      _addLog('Hangout requests collection accessible: ${hangoutCollection.docs.isNotEmpty}');
      _addLog('Total documents in collection: ${hangoutCollection.size}');

    } catch (e) {
      _addLog('ERROR testing Firestore: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}