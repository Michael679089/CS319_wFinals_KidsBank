

// The email and password will be in fireauth


class UserModel {
  final String userId;
  final String familyName;

  UserModel({required this.userId, required this.familyName});

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'family_name': familyName,
    };
  }

  String getUserId () {
    return this.userId; 
  }
}
