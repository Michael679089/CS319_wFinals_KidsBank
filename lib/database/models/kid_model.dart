import 'package:cloud_firestore/cloud_firestore.dart';

class KidModel {
  String? kidId;
  final String familyId;
  final String firstName;
  final String lastName;
  final String dateOfBirth; // ✔ now strictly a string
  final String phoneNumber;
  final String pincode;
  final String avatarFilePath;
  String? createdAt;

  KidModel({
    this.kidId,
    required this.familyId,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.phoneNumber,
    required this.pincode,
    required this.avatarFilePath,
    this.createdAt,
  });

  // Class Functions:

  // receiving data from firestore function:
  factory KidModel.fromMap(Map<String, dynamic> map) {
    return KidModel(
      kidId: map['kidId'],
      familyId: map['familyId'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      dateOfBirth: map["dateOfBirth"],
      phoneNumber: map['phoneNumber'],
      pincode: map['pincode'],
      avatarFilePath: map['avatarFilePath'],
      createdAt: map["createdAt"],
    );
  }

  // sending data to firestore function:
  Map<String, dynamic> toMap() {
    var tempCreatedAt = createdAt;
    if (createdAt == null) {
      tempCreatedAt = FieldValue.serverTimestamp().toString();
    }

    return {
      'kidId': kidId,
      'familyId': familyId,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth, // ✅ stored as String
      'phoneNumber': phoneNumber,
      'pincode': pincode,
      'avatarFilePath': avatarFilePath,
      'createdAt': tempCreatedAt,
    };
  }
}
