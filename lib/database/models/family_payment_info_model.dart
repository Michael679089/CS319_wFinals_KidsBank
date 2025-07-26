// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyPaymentInfoModel {
  String family_payment_info_id;
  String family_id;
  String card_name;
  String card_number;
  double total_amount;
  DateTime exp;
  String ccv;

  FamilyPaymentInfoModel({
    required this.family_payment_info_id,
    required this.family_id,
    required this.card_name,
    required this.card_number,
    required this.total_amount,
    required this.ccv,
    required this.exp,
  });

 

  // FACTORY CONSTRUCTOR FOR FIRESTORE
  // receiving from firestore
  factory FamilyPaymentInfoModel.fromMap(Map<String, dynamic> map) {
    return FamilyPaymentInfoModel(
      family_payment_info_id: map['family_payment_info_id'] as String,
      family_id: map['family_id'] as String,
      card_name: map['card_name']  as String,
      card_number: map['card_number'] as String,
      total_amount: map['total_amount'],
      ccv: map['ccv'] as String,
      exp: (map['exp'] as Timestamp).toDate(), // ✅ safely converts Timestamp to DateTime
    );
  }

  // SERIALIZATION
  // sending from firestore
  Map<String, dynamic> toMap() {
    return {
      'family_payment_info_id': family_payment_info_id,
      'family_id': family_id,
      'card_name': card_name,
      'card_number': card_number,
      'total_amount': total_amount,
      'ccv': ccv,
      'exp': exp,
    };
  }
}
