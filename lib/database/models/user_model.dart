class UserModel {
  final String userId;
  final String familyName;
  final String email;

  UserModel({
    required this.userId,
    required this.familyName,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {'user_id': userId, 'family_name': familyName, 'email': email};
  }
}
