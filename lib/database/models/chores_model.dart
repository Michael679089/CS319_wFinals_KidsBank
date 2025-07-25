import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChoreModel {
  String? choreId;
  final String kidId;
  final String choreTitle;
  final String choreDesc;
  final double rewardMoney;
  final String status;
  final String? timestamp;

  ChoreModel({
    this.choreId,
    required this.kidId,
    required this.choreTitle,
    required this.choreDesc,
    required this.rewardMoney,
    required this.status,
    this.timestamp,
  });

  // receiving data from firestore:
  // Solution:
  // Add null safety, debug context, and Firestore field consistency.

  factory ChoreModel.fromMap(Map<String, dynamic> map) {
    try {
      return ChoreModel(
        choreId: map["choreId"] ?? "(missing choreId)",
        kidId: map["kidId"] ?? map["KidId"] ?? "(missing kidId)",
        choreTitle: map["choreTitle"] ?? "(missing choreTitle)",
        choreDesc: map["choreDesc"] ?? "(missing choreDesc)",
        rewardMoney: (map["rewardMoney"] ?? 0).toDouble(),
        status: map["status"] ?? "(missing status)",
        timestamp: map["timestamp"] ?? "",
      );
    } catch (e) {
      debugPrint("Error in fromMap: $e");
      debugPrint("Map content: $map");
      rethrow;
    }
  }

  // sending data to firestore:
  Map<String, dynamic> toMap() {
    return {
      'choreId': choreId,
      'KidId': kidId,
      'choreTitle': choreTitle,
      'choreDesc': choreDesc,
      'rewardMoney': rewardMoney,
      'status': status,
      'timestamp': timestamp ?? "",
    };
  }
}
