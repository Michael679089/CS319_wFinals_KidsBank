class KidModel {
  final String familyUserId;
  final String firstName;
  final String avatar;

  const KidModel({
    required this.familyUserId,
    required this.firstName,
    required this.avatar,
  });

  factory KidModel.fromMap(Map<String, dynamic> map) {
    return KidModel(
      familyUserId: map['familyUserId'] as String,
      firstName: map['firstName'] as String,
      avatar: map['avatar'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyUserId': familyUserId,
      'firstName': firstName,
      'avatar': avatar,
    };
  }
}
