// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyModel {
  String family_id;
  String family_name;
  String email;
  String password;
  DateTime created_at;

  FamilyModel({
    required this.family_id,
    required this.family_name,
    required this.email,
    required this.password,
    required this.created_at,
  });

  // For Firestore Functions:

  // receiving data from firestore:
  factory FamilyModel.fromMap(Map<String, dynamic> map) {
    return FamilyModel(
      family_id: map["family_id"] as String,
      family_name: map["family_name"] as String,
      email: map["email"] as String,
      password: map["password"] as String,
      created_at: (map["created_at"] as Timestamp).toDate(),
    );
  }

  // sending data to firestore:
  Map<String, dynamic> toMap() {
    return {
      'family_id': family_id,
      'family_name': family_name,
      'email': email,
      'password': password,
      'created_at': created_at,
    };
  }
}
