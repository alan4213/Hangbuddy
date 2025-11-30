import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static String? _verificationId;
  static String? _phoneNumber;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  static Future<void> sendOTP(String phone) async {
    _phoneNumber = phone;
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) {
        print('Auto verification completed');
      },
      verificationFailed: (e) {
        print('Verification failed: ${e.code} - ${e.message}');
        String errorMsg = 'Verification failed';
        switch (e.code) {
          case 'invalid-phone-number':
            errorMsg = 'Invalid phone number format';
            break;
          case 'too-many-requests':
            errorMsg = 'Too many requests. Try again later';
            break;
          case 'quota-exceeded':
            errorMsg = 'SMS quota exceeded';
            break;
          default:
            errorMsg = e.message ?? 'Failed';
        }
        throw errorMsg;
      },
      codeSent: (verificationId, resendToken) {
        print('Code sent, verification ID: $verificationId');
        _verificationId = verificationId;
      },
      codeAutoRetrievalTimeout: (verificationId) {
        print('Auto retrieval timeout');
      },
    );
  }
  
  static Future<bool> verifyOTP(String otp) async {
    try {
      if (_verificationId == null) {
        print('No verification ID found');
        throw 'No verification session found. Please request a new code.';
      }
      
      print('Verifying OTP: $otp with ID: $_verificationId');
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      
      // Check if phone number is already linked to another account
      if (_phoneNumber != null) {
        final existingUser = await _checkPhoneNumberExists(_phoneNumber!);
        if (existingUser != null) {
          print('Phone number already exists, signing in with existing account');
          await FirebaseAuth.instance.signInWithCredential(credential);
          return true;
        }
      }
      
      await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Store phone number in Firestore immediately
      if (_phoneNumber != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'phoneNumber': _phoneNumber,
            'uid': user.uid,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          }, SetOptions(merge: true));
          print('Phone number stored: $_phoneNumber');
        }
      }
      
      print('OTP verification successful');
      return true;
    } catch (e) {
      print('OTP verification failed: $e');
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-verification-code':
            throw 'Invalid verification code. Please check and try again.';
          case 'session-expired':
            throw 'Verification session expired. Please request a new code.';
          case 'too-many-requests':
            throw 'Too many attempts. Please try again later.';
          default:
            throw e.message ?? 'Verification failed. Please try again.';
        }
      }
      throw 'Verification failed. Please try again.';
    }
  }
  
  // Check if phone number already exists in database
  static Future<DocumentSnapshot?> _checkPhoneNumberExists(String phoneNumber) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty ? query.docs.first : null;
    } catch (e) {
      print('Error checking phone number: $e');
      return null;
    }
  }
  
  static Future<AuthCredential?> getGoogleCredential() async {
    try {
      print('Getting Google credential for linking...');
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      
      final googleAuth = await googleUser.authentication;
      return GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
    } catch (e) {
      print('Error getting Google credential: $e');
      rethrow;
    }
  }

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      print('=== Starting Google Sign-In ===');
      
      // Sign out first to force account selection
      await _googleSignIn.signOut();
      
      final googleUser = await _googleSignIn.signIn();
      print('GoogleSignIn.signIn() completed');
      print('Google user result: $googleUser');
      print('Google user email: ${googleUser?.email}');
      print('Google user displayName: ${googleUser?.displayName}');
      
      if (googleUser == null) {
        print('Google sign-in was cancelled by user or failed');
        return null;
      }
      
      print('Getting Google authentication tokens...');
      final googleAuth = await googleUser.authentication;
      print('Access token available: ${googleAuth.accessToken != null}');
      print('ID token available: ${googleAuth.idToken != null}');
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      print('Signing in with Firebase using Google credential...');
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      print('Firebase sign-in successful: ${result.user?.email}');
      print('=== Google Sign-In Complete ===');
      return result;
    } catch (e, stackTrace) {
      print('=== Google Sign-In Error ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('Error type: ${e.runtimeType}');
      rethrow;
    }
  }
  
  // Check if email already exists and return sign-in methods
  static Future<List<String>> checkExistingEmail(String email) async {
    try {
      return await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
    } catch (e) {
      print('Error checking existing email: $e');
      return [];
    }
  }
  
  // Merge phone and Google accounts
  static Future<bool> mergePhoneAndGoogleAccounts(String phoneNumber) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;
      
      // Update user profile with phone number
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
        'phoneNumber': phoneNumber,
        'uid': currentUser.uid,
        'email': currentUser.email,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
      
      print('Successfully merged phone number $phoneNumber with Google account');
      return true;
    } catch (e) {
      print('Error merging accounts: $e');
      return false;
    }
  }
  
  // Clean up duplicate accounts
  static Future<void> cleanupDuplicateAccount(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      print('Cleaned up duplicate account: $uid');
    } catch (e) {
      print('Error cleaning up duplicate account: $e');
    }
  }
}