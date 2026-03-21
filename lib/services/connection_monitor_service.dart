import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionMonitorService {
  static Timer? _connectionTimer;
  static bool _isMonitoring = false;

  static void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    // Periodic connection check (every 5 minutes)
    _connectionTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkFirebaseConnection();
    });
  }

  static void stopMonitoring() {
    _isMonitoring = false;
    _connectionTimer?.cancel();
  }

  static Future<void> _checkFirebaseConnection() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Try to refresh the token
        await user.getIdToken(true);
        
        // Test Firestore connection with timeout
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 10));
            
        print('Firebase connection check: OK');
      }
    } catch (e) {
      print('Connection check failed: $e');
      // Don't logout automatically, just log the error
      if (e.toString().contains('permission-denied')) {
        print('Permission denied - this is likely a Samsung device issue');
      }
    }
  }

  static Future<void> refreshConnection() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.getIdToken(true);
        print('Token refreshed successfully');
      }
    } catch (e) {
      print('Token refresh failed: $e');
    }
  }
}