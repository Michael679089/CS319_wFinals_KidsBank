import 'package:cloud_firestore/cloud_firestore.dart';

class KidModel {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String phone;
  final String pincode;
  final String avatar;
  final String familyUserId;
  final DateTime? createdAt;

  const KidModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.phone,
    required this.pincode,
    required this.avatar,
    required this.familyUserId,
    this.createdAt,
  });

  /// Creates a [KidModel] from a Firestore document map.
  ///
  /// [map] The Firestore document data as a Map.
  /// Returns a [KidModel] with fields populated from the map, using defaults for missing values.
  factory KidModel.fromMap(Map<String, dynamic> map) {
    return KidModel(
      id: map['id']?.toString() ?? '',
      firstName: map['firstName']?.toString() ?? '',
      lastName: map['lastName']?.toString() ?? '',
      dateOfBirth:
          (map['date_of_birth'] as Timestamp?)?.toDate() ?? DateTime.now(),
      phone: map['phone']?.toString() ?? '',
      pincode: map['pincode']?.toString() ?? '',
      avatar: map['avatar']?.toString() ?? '',
      familyUserId:
          map['familyUserId']?.toString() ?? map['user_id']?.toString() ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts the [KidModel] to a Firestore-compatible map.
  ///
  /// Throws an [Exception] if any required field is null or empty.
  Map<String, dynamic> toMap() {
    if (id.isEmpty) throw Exception('KidModel: id cannot be null or empty');
    if (firstName.isEmpty) {
      throw Exception('KidModel: firstName cannot be null or empty');
    }
    if (lastName.isEmpty) {
      throw Exception('KidModel: lastName cannot be null or empty');
    }
    if (phone.isEmpty) {
      throw Exception('KidModel: phone cannot be null or empty');
    }
    if (pincode.isEmpty) {
      throw Exception('KidModel: pincode cannot be null or empty');
    }
    if (avatar.isEmpty) {
      throw Exception('KidModel: avatar cannot be null or empty');
    }
    if (familyUserId.isEmpty) {
      throw Exception('KidModel: familyUserId cannot be null or empty');
    }

    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'date_of_birth': Timestamp.fromDate(dateOfBirth),
      'phone': phone,
      'pincode': pincode,
      'avatar': avatar,
      'familyUserId': familyUserId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
