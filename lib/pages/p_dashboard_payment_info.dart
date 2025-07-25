import 'package:flutter/material.dart';
import 'package:wfinals_kidsbank/database/models/family_payment_info_model.dart';

class ParentDashboardPaymentInfo extends StatefulWidget {
  const ParentDashboardPaymentInfo({super.key});

  @override
  State<StatefulWidget> createState() => _ParentDashboardPaymentInfo();
}

class _ParentDashboardPaymentInfo extends State<ParentDashboardPaymentInfo> {
  FamilyPaymentInfoModel? kidsWalletModel;
  FamilyPaymentInfoModel? parentWallet;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("EEEEE")),
      body: Column(children: [

      ],),
    );
  }
}
