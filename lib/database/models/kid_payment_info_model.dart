// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

class KidsPaymentInfoModel {
  String? id;
  String kid_id;
  String family_id;
  String phone_number;
  double total_amount_left;
  DateTime? created_at;

  KidsPaymentInfoModel({
    this.id,
    required this.kid_id,
    required this.family_id,
    required this.phone_number,
    required this.total_amount_left,
    this.created_at,
  });

  // receiving from firestore
  factory KidsPaymentInfoModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return KidsPaymentInfoModel(
      id: snapshot.id, // Get the document ID here
      kid_id: data["kid_id"], // Get the document ID here
      family_id: data['family_id'] as String,
      phone_number: data['phone_number'] as String,
      total_amount_left: data['total_amount_left'] as double,
      created_at: (data['created_at'] as Timestamp).toDate(),
    );
  }

  // sending to firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'kid_id': kid_id,
      'family_id': family_id,
      'phone_number': phone_number,
      'total_amount_left': total_amount_left,
      'created_at': created_at,
    };
  }
}
