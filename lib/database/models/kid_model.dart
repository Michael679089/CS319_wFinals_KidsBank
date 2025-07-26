// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

class KidModel {
  String kid_id;
  String family_id;
  String first_name;
  String last_name;
  DateTime date_of_birth; // ✔ now strictly a string
  String phone_number;
  String pincode;
  String avatar_file_path;
  DateTime created_at;

  KidModel({
    required this.kid_id,
    required this.family_id,
    required this.first_name,
    required this.last_name,
    required this.date_of_birth,
    required this.phone_number,
    required this.pincode,
    required this.avatar_file_path,
    required this.created_at,
  });

  // Class Functions:

  // receiving data from firestore function:
  factory KidModel.fromMap(Map<String, dynamic> map) {
    return KidModel(
      kid_id: map['kid_id'],
      family_id: map['family_id'],
      first_name: map['first_name'],
      last_name: map['last_name'],
      date_of_birth: (map["date_of_birth"] as Timestamp).toDate(),
      phone_number: map['phone_number'],
      pincode: map['pincode'],
      avatar_file_path: map['avatar_file_path'],
      created_at: (map["created_at"] as Timestamp).toDate(),
    );
  }

  // sending data to firestore function:
  Map<String, dynamic> toMap() {
    return {
      'kid_id': kid_id,
      'family_id': family_id,
      'first_name': first_name,
      'last_name': last_name,
      'date_of_birth': date_of_birth, // ✅ stored as String
      'phone_number': phone_number,
      'pincode': pincode,
      'avatar_file_path': avatar_file_path,
      'created_at': created_at,
    };
  }
}
