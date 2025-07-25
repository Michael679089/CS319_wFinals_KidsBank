class NotificationsModel {
  String? notificationId;
  final String familyId;
  final String kidId;
  final String title;
  final String? message;
  final String type;
  final String? createdAt;

  NotificationsModel({
    this.notificationId,
    required this.familyId,
    required this.kidId,
    required this.title,
    this.message,
    required this.type,
    this.createdAt,
  });

  // receiving from firestore
  factory NotificationsModel.fromMap(Map<String, dynamic> map) {
    return NotificationsModel(
      notificationId: map["notificationId"] as String,
      familyId: map['familyId'] as String,
      kidId: map["kidId"] as String,
      title: map["title"] as String,
      message: map['message'] as String,
      type: map['status'] as String,
      createdAt: map['createdAt'] as String,
    );
  }

  // sending to firestore
  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'familyId': familyId,
      'kidId': kidId,
      'title': title,
      'message': message ?? "",
      'type': type,
      'createdAt': createdAt,
    };
  }
}
