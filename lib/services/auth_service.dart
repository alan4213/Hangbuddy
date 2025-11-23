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
}