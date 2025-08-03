// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  String? id;
  String family_id;
  String kid_id;
  String notification_title;
  String notification_message;
  String type;
  double amount; //added the amount for each transaction
  DateTime? created_at;

  NotificationModel({
    this.id,
    required this.family_id,
    required this.kid_id,
    required this.notification_title,
    required this.notification_message,
    required this.type,
    required this.amount,
    this.created_at,
  });

  // receiving from firestore
  factory NotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return NotificationModel(
      id: snapshot.id, // Get the document ID here
      family_id: data['family_id'] as String,
      kid_id: data['kid_id'] as String,
      notification_title: data['notification_title'] as String,
      notification_message: data['notification_message'] as String,
      type: data['type'] as String,
      amount: (data['amount'] ?? 0).toDouble(),
      created_at: data["created_at"],
    );
  }

  // sending to firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'family_id': family_id,
      'kid_id': kid_id,
      'notification_title': notification_title,
      'notification_message': notification_message,
      'type': type,
      'amount': amount,
      'created_at': created_at,
    };
  }
}
