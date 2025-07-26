// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsModel {
  String notification_id;
  String family_id;
  String kid_id;
  String notification_title;
  String notification_message;
  double notification_amount;
  String type;
  DateTime created_at;

  NotificationsModel({
    required this.notification_id,
    required this.family_id,
    required this.kid_id,
    required this.notification_title,
    required this.notification_message,
    required this.notification_amount,
    required this.type,
    required this.created_at
  });

  // receiving from firestore
  factory NotificationsModel.fromMap(Map<String, dynamic> map) {
    return NotificationsModel(
      notification_id: map["notification_id"],
      family_id: map["family_id"],
      kid_id: map["kid_id"],
      notification_title: map["notification_title"],
      notification_message:  map["notification_message"],
      notification_amount:  map["notification_amount"],
      type:  map["type"],
      created_at: (map['created_at'] as Timestamp).toDate(),
    );
  }

  // sending to firestore
  Map<String, dynamic> toMap() {
    return {
      'notification_id': notification_id,
      'family_id': family_id,
      'kid_id': kid_id,
      'notification_title': notification_title,
      'notification_message': notification_message,
      'notification_amount': notification_amount,
      'type': type,
      'created_at': created_at,
    };
  }
}
