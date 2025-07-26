// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

class KidsPaymentInfoModel {
  String kid_payment_info_id;
  String kid_id;
  String phone_number;
  String total_amount;
  DateTime last_updated;
  DateTime created_at;

  KidsPaymentInfoModel({
    required this.kid_payment_info_id,
    required this.kid_id,
    required this.phone_number,
    required this.total_amount,
    required this.last_updated,
    required this.created_at,
  });

  // receiving from firestore
  factory KidsPaymentInfoModel.fromMap(Map<String, dynamic> map) {
    return KidsPaymentInfoModel(
      kid_payment_info_id: map["kid_payment_info_id"] as String,
      kid_id: map['kid_id'] as String,
      phone_number: map["phone_number"] as String,
      total_amount: map['total_amount'] as String,
      last_updated: (map['last_updated'] as Timestamp).toDate(),
      created_at: (map["created_at"] as Timestamp).toDate()
    );
  }

  // sending to firestore
  Map<String, dynamic> toMap() {
    return {
      'kid_payment_info_id': kid_payment_info_id,
      'kid_id': kid_id,
      'phone_number': phone_number,
      'total_amount': total_amount,
      'last_updated': last_updated,
    };
  }
}
