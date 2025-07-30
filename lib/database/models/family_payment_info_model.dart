// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyPaymentInfoModel {
  String? id; // This will store the Firestore document ID
  String user_id;
  String card_name;
  String card_number;
  double? total_amount_left;
  DateTime exp;
  String ccv;

  FamilyPaymentInfoModel({
    this.id,
    required this.user_id,
    required this.card_name,
    required this.card_number,
    this.total_amount_left,
    required this.ccv,
    required this.exp,
  });

  // Factory constructor to create from Firestore document
  factory FamilyPaymentInfoModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return FamilyPaymentInfoModel(
      id: snapshot.id, // Get the document ID here
      user_id: data['user_id'] as String,
      card_name: data['card_name'] as String,
      card_number: data['card_number'] as String,
      total_amount_left: data['total_amount_left']?.toDouble() ?? 0.0,
      ccv: data['ccv'] as String,
      exp: (data['exp'] as Timestamp).toDate(),
    );
  }

  // Convert to map for Firestore (without the ID)
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': user_id,
      'card_name': card_name,
      'card_number': card_number,
      'total_amount_left': total_amount_left,
      'ccv': ccv,
      'exp': exp, // Firestore will automatically convert DateTime
    };
  }
}
