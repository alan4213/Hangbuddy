class SignupData {
  String? firstName;
  String? lastName;
  String? email;
  DateTime? birthday;
  String? gender;
  String? occupation;
  String? education;
  String? height;
  String? race;
  String? religion;
  List<String> interests = [];
  List<String> photoUrls = [];

  SignupData();

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'birthday': birthday?.millisecondsSinceEpoch,
      'gender': gender,
      'occupation': occupation,
      'education': education,
      'height': height,
      'race': race,
      'religion': religion,
      'interests': interests,
      'photoUrls': photoUrls,
    };
  }
}