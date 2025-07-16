class UserModel {
  final String userId;
  final String familyName;
  final String email;
  final String createdAt; // use snake_case if consistent

  UserModel({
    required this.userId,
    required this.familyName,
    required this.email,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'family_name': familyName,
      'email': email,
      'createdAt': createdAt,
    };
  }
}
