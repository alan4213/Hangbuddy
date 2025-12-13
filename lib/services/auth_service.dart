import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'notification_service.dart';

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
      
      // Refresh FCM token after successful login
      await NotificationService.refreshFCMToken();
      
      // Store phone number in Firestore immediately
      if (_phoneNumber != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Check if there's already a Google account with same email in Firestore
          final existingGoogleUser = await _checkExistingGoogleAccount(user.email);
          if (existingGoogleUser != null) {
            print('Found existing Google account, merging phone number');
            // Delete current phone-only account and use existing Google account
            await user.delete();
            // Sign in with existing Google account and add phone number
            await _mergeWithExistingGoogleAccount(existingGoogleUser, _phoneNumber!);
            return true;
          }
          
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
  
  // Check if Google account already exists in Firestore
  static Future<DocumentSnapshot?> _checkExistingGoogleAccount(String? email) async {
    if (email == null) return null;
    
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty ? query.docs.first : null;
    } catch (e) {
      print('Error checking existing Google account: $e');
      return null;
    }
  }
  
  // Merge phone number with existing Google account
  static Future<void> _mergeWithExistingGoogleAccount(DocumentSnapshot existingUser, String phoneNumber) async {
    try {
      final existingUid = existingUser.id;
      
      // Update existing Google account with phone number
      await FirebaseFirestore.instance.collection('users').doc(existingUid).update({
        'phoneNumber': phoneNumber,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      print('Successfully merged phone number $phoneNumber with existing Google account $existingUid');
    } catch (e) {
      print('Error merging with existing Google account: $e');
      throw e;
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
      
      // Refresh FCM token after successful login
      await NotificationService.refreshFCMToken();
      
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
  
  // Store email (no verification needed for phone users)
  static Future<void> sendEmailLink(String email) async {
    try {
      // Just store the email in Firestore
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'email': email,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
        print('Email stored: $email');
      }
    } catch (e) {
      print('Error storing email: $e');
      throw e;
    }
  }
  
  // Initialize dynamic links listener
  static void initializeDynamicLinks() {
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
      final Uri deepLink = dynamicLinkData.link;
      handleDynamicLink(deepLink);
    }).onError((error) {
      print('Dynamic link error: $error');
    });
  }
  
  // Handle dynamic link
  static Future<void> handleDynamicLink(Uri link) async {
    try {
      final email = link.queryParameters['email'];
      if (email != null && FirebaseAuth.instance.isSignInWithEmailLink(link.toString())) {
        await signInWithEmailLink(email, link.toString());
      }
    } catch (e) {
      print('Error handling dynamic link: $e');
    }
  }
  
  // Verify email link and sign in
  static Future<UserCredential?> signInWithEmailLink(String email, String emailLink) async {
    try {
      if (FirebaseAuth.instance.isSignInWithEmailLink(emailLink)) {
        final result = await FirebaseAuth.instance.signInWithEmailLink(
          email: email,
          emailLink: emailLink,
        );
        
        // Store in Firestore
        if (result.user != null) {
          await FirebaseFirestore.instance.collection('users').doc(result.user!.uid).set({
            'email': email,
            'uid': result.user!.uid,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          }, SetOptions(merge: true));
        }
        
        return result;
      }
      return null;
    } catch (e) {
      print('Error signing in with email link: $e');
      throw e;
    }
  }
  
  // Find user by email in Firestore
  static Future<DocumentSnapshot?> findUserByEmail(String email) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty ? query.docs.first : null;
    } catch (e) {
      print('Error finding user by email: $e');
      return null;
    }
  }
  
  // Temporary: Create account with email and simple password
  static Future<UserCredential?> createEmailAccount(String email) async {
    try {
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: 'hangbuddy123',
      );
      
      if (result.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(result.user!.uid).set({
          'email': email,
          'uid': result.user!.uid,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      }
      
      return result;
    } catch (e) {
      print('Error creating email account: $e');
      throw e;
    }
  }
}