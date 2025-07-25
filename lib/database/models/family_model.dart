class FamilyModel {
  String? familyId;
  final String familyName;
  final String email;
  final String? password;
  final String? createdAt;

  FamilyModel({
    this.familyId,
    required this.familyName,
    required this.email,
    this.password,
    this.createdAt,
  });

  // For Firestore Functions:

  // receiving data from firestore:
  factory FamilyModel.fromMap(Map<String, dynamic> map) {
    return FamilyModel(
      familyId: map["familyId"] as String,
      familyName: map["familyName"] as String,
      email: map["email"] as String,
      password: map["password"] as String,
      createdAt: map["createdAt"] as String,
    );
  }

  // sending data to firestore:
  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'familyName': familyName,
      'email': email,
      'createdAt': createdAt,
    };
  }
}
