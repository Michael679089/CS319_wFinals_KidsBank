import 'package:cloud_firestore/cloud_firestore.dart';

class ParentModel {
  String? parentId;
  final String familyId;
  final String firstName;
  final String lastName;
  final String dateOfBirth;
  final String pincode;
  final String avatarFilePath;
  String? createdAt;

  // CONSTRUCTORS
  ParentModel({
    this.parentId,
    required this.familyId,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.pincode,
    required this.avatarFilePath,
    this.createdAt,
  });

  // FACTORY CONSTRUCTOR FOR FIRESTORE

  // receiving from firestore
  factory ParentModel.fromMap(Map<String, dynamic> map) {
    return ParentModel(
      parentId: map["parentId"] as String,
      familyId: map['familyId'] as String,
      firstName: map["firstName"] as String,
      lastName: map['lastName'] as String,
      dateOfBirth: map['dateOfBirth'] ?? map['birthdate'] as String,
      pincode: map['pincode'] as String,
      avatarFilePath: map["avatarFilePath"] as String,
      createdAt: map['createdAt'] as String,
    );
  }

  // SERIALIZATION
  // sending to firestore
  Map<String, dynamic> toMap() {
    var tempCreatedAt = "";
    if (createdAt == null) {
      tempCreatedAt = FieldValue.serverTimestamp().toString();
    }

    return {
      'parentId': parentId,
      'familyId': familyId,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'pincode': pincode,
      'avatarFilePath': avatarFilePath,
      'createdAt': tempCreatedAt,
    };
  }
}
