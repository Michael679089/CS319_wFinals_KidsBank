// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

class ParentModel {
  String? id;
  String family_id;
  String first_name;
  String last_name;
  DateTime date_of_birth;
  String pincode;
  String avatar_file_path; // for the profile picture
  DateTime created_at;

  // CONSTRUCTORS
  ParentModel({
    this.id,
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
  // Factory constructor to create from Firestore document
  factory ParentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;
    return ParentModel(
      id: snapshot.id, // Get the document ID here
      family_id: data['family_id'] as String,
      first_name: data['first_name'] as String,
      last_name: data['last_name'] as String,
      date_of_birth: (data['date_of_birth'] as Timestamp).toDate(),
      pincode: data["pincode"],
      avatar_file_path: data["avatar_file_path"],
      created_at: (data["created_at"] as Timestamp).toDate(),
    );
  }

  // SERIALIZATION
  // sending to firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
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
