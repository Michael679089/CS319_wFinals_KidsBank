

class ParentModel {
  final String parentId;
  final String firstName;
  final String lastName;
  final String pincode;
  final String userId;
  final DateTime dateOfBirth;

  ParentModel({
    required this.parentId,
    required this.firstName,
    required this.lastName,
    required this.pincode,
    required this.userId,
    required this.dateOfBirth,
  });

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'firstName': firstName,
      'lastName': lastName,
      'pincode': pincode,
      'userId': userId,
      'dateOfBirth': dateOfBirth.toIso8601String(),
    };
  }
}
