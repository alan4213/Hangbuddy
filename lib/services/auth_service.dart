import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static String? _verificationId;
  
  static Future<void> sendOTP(String phone) async {
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
        return false;
      }
      
      print('Verifying OTP: $otp with ID: $_verificationId');
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      print('OTP verification successful');
      return true;
    } catch (e) {
      print('OTP verification failed: $e');
      return false;
    }
  }
}