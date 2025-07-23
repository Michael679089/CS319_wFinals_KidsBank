import 'package:cloud_firestore/cloud_firestore.dart';

class ParentModel {
  final String avatar;
  final String familyUserId;
  final String firstName;
  final String lastName;
  final String pincode;
  final String birthdate;
  final DateTime? createdAt;

  // CONSTRUCTORS
  const ParentModel({
    required this.avatar,
    required this.familyUserId,
    required this.firstName,
    required this.lastName,
    required this.pincode,
    required this.birthdate,
    this.createdAt,
  });

  // FACTORY CONSTRUCTOR FOR FIRESTORE
  factory ParentModel.fromMap(Map<String, dynamic> map) {
    return ParentModel(
      avatar: map["avatar"] as String,
      familyUserId: map['familyUserId'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      pincode: map['pincode'] as String,
      birthdate: map['birthdate'] as String,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // SERIALIZATION
  Map<String, dynamic> toMap({String? parentId}) {
    return {
      'avatar': avatar,
      'familyUserId': familyUserId,
      if (parentId != null)
        'parentId': parentId, // Include parentId if provided
      'firstName': firstName,
      'lastName': lastName,
      'pincode': pincode,
      'birthdate': birthdate,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
