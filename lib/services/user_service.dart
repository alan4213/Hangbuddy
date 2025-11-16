import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static int? _calculateAge(DateTime? birthday) {
    if (birthday == null) return null;
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month || (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }

  static Future<void> createUserProfile({
    required String firstName,
    required String lastName,
    DateTime? birthday,
    String? gender,
    List<String>? interests,
    String? profileImageUrl,
    String? occupation,
    String? education,
    String? height,
    String? race,
    String? religion,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final userData = {
      'uid': user.uid,
      'phoneNumber': user.phoneNumber ?? '',
      'firstName': firstName,
      'lastName': lastName,
      'birthday': birthday?.millisecondsSinceEpoch,
      'age': _calculateAge(birthday),
      'gender': gender,
      'interests': interests ?? [],
      'profileImageUrl': profileImageUrl,
      'occupation': occupation,
      'education': education,
      'height': height,
      'race': race,
      'religion': religion,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(userData);
  }

  static Future<UserModel?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data()!);
  }

  static Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    DateTime? birthday,
    String? gender,
    List<String>? interests,
    String? profileImageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    if (firstName != null) updates['firstName'] = firstName;
    if (lastName != null) updates['lastName'] = lastName;
    if (birthday != null) {
      updates['birthday'] = birthday.millisecondsSinceEpoch;
      updates['age'] = _calculateAge(birthday);
    }
    if (gender != null) updates['gender'] = gender;
    if (interests != null) updates['interests'] = interests;
    if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .update(updates);
  }
}