class FamilyPaymentInfoModel {
  String? familyPaymentInfoId;
  final String familyId;
  final String cardName;
  final String cardNumber;
  final String ccv;
  final String exp;

  FamilyPaymentInfoModel({
    this.familyPaymentInfoId,
    required this.familyId,
    required this.cardName,
    required this.cardNumber,
    required this.ccv,
    required this.exp,
  });

  // FACTORY CONSTRUCTOR FOR FIRESTORE
  factory FamilyPaymentInfoModel.fromMap(Map<String, dynamic> map) {
    return FamilyPaymentInfoModel(
      familyPaymentInfoId: map["familyPaymentInfoId"] as String,
      familyId: map['familyId'] as String,
      cardName: map["cardName"] as String,
      cardNumber: map['cardNumber'] as String,
      ccv: map['ccv'] as String,
      exp: map['exp'] as String,
    );
  }

  // SERIALIZATION
  Map<String, dynamic> toMap() {
    return {
      'familyPaymentInfoId': familyPaymentInfoId,
      'familyId': familyId,
      'cardName': cardName,
      'cardNumber': cardNumber,
      'ccv': ccv,
      'exp': exp,
    };
  }
}
