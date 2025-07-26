// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

class ChoreModel {
  String chore_id;
  String kid_id;
  String chore_title;
  String chore_description;
  double reward_money;
  String status;
  DateTime timestamp;

  ChoreModel({
    required this.chore_id,
    required this.kid_id,
    required this.chore_title,
    required this.chore_description,
    required this.reward_money,
    required this.status, 
    required this.timestamp,
  });

  // receiving data from firestore:
  // Solution:
  // Add null safety, debug context, and Firestore field consistency.

  factory ChoreModel.fromMap(Map<String, dynamic> map) {
    return ChoreModel(
      chore_id: map["chore_id"],
      kid_id: map["kid_id"],
      chore_title: map["chore_title"],
      chore_description: map["chore_description"],
      reward_money: map["reward_money"],
      status: map["status"],
      timestamp: (map["timestamp"] as Timestamp).toDate(),
    );
  }

  // sending data to firestore:
  Map<String, dynamic> toMap() {
    return {
      'chore_id': chore_id,
      'kid_id': kid_id,
      'chore_title': chore_title,
      'chore_description': chore_description,
      'reward_money': reward_money,
      'status': status,
      'timestamp': timestamp,
    };
  }
}
