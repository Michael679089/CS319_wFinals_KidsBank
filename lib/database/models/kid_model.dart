// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

class KidModel {
  String? id;
  String family_id;
  String first_name;
  String last_name;
  DateTime date_of_birth; // ✔ now strictly a string
  String pincode;
  String avatar_file_path;
  DateTime? created_at;

  KidModel({
    this.id,
    required this.family_id,
    required this.first_name,
    required this.last_name,
    required this.date_of_birth,
    required this.pincode,
    required this.avatar_file_path,
    this.created_at,
  });

  // Class Functions:

  // receiving data from firestore function:
  // receiving from firestore
  // Factory constructor to create from Firestore document
  factory KidModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;
    return KidModel(
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
