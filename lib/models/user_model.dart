class UserModel {
  final String uid;
  final String phoneNumber;
  final String firstName;
  final String lastName;
  final DateTime? birthday;
  final int? age;
  final String? gender;
  final List<String>? interests;
  final String? education;
  final String? ethnicity;
  final String? race;
  final String? occupation;
  final String? height;
  final String? religion;
  final String? profileImageUrl;
  final List<String>? photoUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    this.birthday,
    this.age,
    this.gender,
    this.interests,
    this.education,
    this.ethnicity,
    this.race,
    this.occupation,
    this.height,
    this.religion,
    this.profileImageUrl,
    this.photoUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'firstName': firstName,
      'lastName': lastName,
      'birthday': birthday?.millisecondsSinceEpoch,
      'age': age,
      'gender': gender,
      'interests': interests,
      'education': education,
      'ethnicity': ethnicity,
      'race': race,
      'occupation': occupation,
      'height': height,
      'religion': religion,
      'profileImageUrl': profileImageUrl,
      'photoUrls': photoUrls,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      birthday: map['birthday'] != null ? DateTime.fromMillisecondsSinceEpoch(map['birthday']) : null,
      age: map['age'],
      gender: map['gender'],
      interests: map['interests'] != null ? List<String>.from(map['interests']) : null,
      education: map['education'],
      ethnicity: map['ethnicity'],
      race: map['race'],
      occupation: map['occupation'],
      height: map['height'],
      religion: map['religion'],
      profileImageUrl: map['profileImageUrl'],
      photoUrls: map['photoUrls'] != null ? List<String>.from(map['photoUrls']) : null,
      createdAt: map['createdAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt']) : DateTime.now(),
    );
  }
}