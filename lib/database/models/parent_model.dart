// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

class ParentModel {
  String parent_id;
  String family_id;
  String first_name;
  String last_name;
  DateTime date_of_birth;
  String pincode;
  String avatar_file_path;
  DateTime created_at;

  // CONSTRUCTORS
  ParentModel({
    required this.parent_id,
    required this.family_id,
    required this.first_name,
    required this.last_name,
    required this.date_of_birth,
    required this.pincode,
    required this.avatar_file_path,
    required this.created_at,
  });

  // FACTORY CONSTRUCTOR FOR FIRESTORE

  // receiving from firestore
  factory ParentModel.fromMap(Map<String, dynamic> map) {
    return ParentModel(
      parent_id: map["parent_id"] as String,
      family_id: map['family_id'] as String,
      first_name: map["first_name"] as String,
      last_name: map['last_name'] as String,
      date_of_birth: (map['date_of_birth'] as Timestamp).toDate(),
      pincode: map['pincode'] as String,
      avatar_file_path: map["avatarFilePath"] as String,
      created_at: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // SERIALIZATION
  // sending to firestore
  Map<String, dynamic> toMap() {
    return {
       'parent_id': parent_id,
       'family_id': family_id,
       'first_name': first_name,
       'last_name': last_name,
       'date_of_birth': date_of_birth,
       'pincode': pincode,
       'avatar_file_path': avatar_file_path,
       'created_at': created_at,
    };
  }
}
