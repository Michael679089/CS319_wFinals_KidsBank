// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

class ChoreModel {
  String? id;
  String kid_id;
  String chore_title;
  String chore_description;
  double reward_money;
  String status;
  DateTime? created_at;

  ChoreModel({
    required this.id,
    required this.kid_id,
    required this.chore_title,
    required this.chore_description,
    required this.reward_money,
    required this.status,
    this.created_at,
  });

  // receiving data from Firestore
  factory ChoreModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return ChoreModel(
      id: snapshot.id,
      kid_id: data['kid_id'] as String,
      chore_title: data['chore_title'] as String,
      chore_description: data['chore_description'] as String,
      reward_money: (data['reward_money'] as num).toDouble(),
      status: data['status'] as String,
      created_at: (data["created_at"] as Timestamp).toDate(),
    );
  }

  // sending data to Firestore
  Map<String, dynamic> toMap() {
    return {
      'kid_id': kid_id,
      'chore_title': chore_title,
      'chore_description': chore_description,
      'reward_money': reward_money,
      'status': status,
      'created_at': created_at,
    };
  }
}
