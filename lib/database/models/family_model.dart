// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyModel {
  String? id;
  String user_id;
  String family_name;
  String email;
  String? password;
  DateTime? created_at;

  FamilyModel({this.id, required this.user_id, required this.family_name, required this.email, this.password, this.created_at});

  // For Firestore Functions:

  // receiving data from firestore:
  // Factory constructor to create from Firestore document
  factory FamilyModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;
    return FamilyModel(
      id: snapshot.id, // Get the document ID here
      user_id: data["user_id"],
      family_name: data['family_name'] as String,
      email: data['email'] as String,
      created_at: (data['created_at'] as Timestamp).toDate(),
    );
  }

  // sending data to firestore:
  Map<String, dynamic> toFirestore() {
    return {'id': id, 'user_id': user_id, 'family_name': family_name, 'email': email, 'created_at': created_at};
  }
}
