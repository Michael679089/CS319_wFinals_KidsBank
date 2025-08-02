import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionsModel {
  String? id;
  final String type;
  final double amount;
  final DateTime created_at;
  final String family_id;

  TransactionsModel({this.id, required this.type, required this.amount, required this.family_id, required this.created_at});

  // FACTORY CONSTRUCTOR FOR FIRESTORE

  // receiving from firestore
  // Factory constructor to create from Firestore document
  factory TransactionsModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;
    return TransactionsModel(
      id: snapshot.id, // Get the document ID here
      type: data['type'],
      amount: data['amount'],
      family_id: data["family_id"],
      created_at: (data["created_at"] as Timestamp).toDate(),
    );
  }

  // SERIALIZATION
  // sending to firestore
  Map<String, dynamic> toFirestore() {
    return {'id': id, 'type': type, 'amount': amount, "family_id": family_id, 'created_at': created_at};
  }
}
