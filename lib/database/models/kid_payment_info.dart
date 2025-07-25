class KidsPaymentInfoModel {
  String? kidPaymentInfoId;
  final String kidId;
  final String? phoneNumber;
  String? amountLeft;
  final String? lastUpdated;

  KidsPaymentInfoModel({
    this.kidPaymentInfoId,
    required this.kidId,
    this.phoneNumber,
    this.amountLeft,
    this.lastUpdated,
  });

  // receiving from firestore
  factory KidsPaymentInfoModel.fromMap(Map<String, dynamic> map) {
    return KidsPaymentInfoModel(
      kidPaymentInfoId: map["kidPaymentInfoId"] as String,
      kidId: map['kidId'] as String,
      phoneNumber: map["phoneNumber"] as String,
      amountLeft: map['amountLeft'] as String,
      lastUpdated: map['lastUpdated'] as String,
    );
  }

  // sending to firestore
  Map<String, dynamic> toMap() {
    return {
      'kidPaymentInfoId': kidPaymentInfoId,
      'kidId': kidId,
      'phoneNumber': phoneNumber,
      'amountLeft': amountLeft ?? 0.toString(),
      'lastUpdated': lastUpdated,
    };
  }
}
