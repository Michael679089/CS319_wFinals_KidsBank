import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/chores_model.dart';
import 'package:wfinals_kidsbank/database/models/kid_model.dart';
import 'package:wfinals_kidsbank/database/models/kid_payment_info_model.dart';
import 'package:wfinals_kidsbank/database/models/notifications_model.dart';
import 'package:wfinals_kidsbank/pages/p_dashboard_drawer.dart';
import 'package:wfinals_kidsbank/utilities/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart'; 

class ParentDashboard extends StatefulWidget {
  final String user_id;
  final String parent_id;
  final List<Map<String, dynamic>> kidsData;
  final String family_id;
 

  const ParentDashboard({
    super.key,
    required this.user_id,
    required this.parent_id,
    required this.kidsData,
    required this.family_id,
  });

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

double totalDepositedFunds = 0.0;

class _ParentDashboardState extends State<ParentDashboard> {
  // The Kids_Data Example: [{"kid_id": "abc123", "first_name": "Joshua", "balance": 25.50}];
  List<Map<String, dynamic>> Kids_Data = [];
  int totalChildren = 0;
  String? familyId;
  final List<Color> tileColors = [
    const Color.fromARGB(255, 252, 193, 220),
    const Color.fromARGB(255, 209, 241, 212),
    const Color.fromARGB(255, 251, 194, 215),
    const Color.fromARGB(255, 224, 182, 238),
    const Color.fromARGB(255, 240, 217, 233),
  ];

  String myFamilyName = "";

  // The INITSTATE Function

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint("PDashboard - loading kids data");
      _loadKidsData();
      debugPrint("PDashboard - loading family data");
      _loadMyFamilyData();
    });
  }

  // Other Functions:

  void _loadMyFamilyData() async {
    myFamilyName = await FirestoreService.fetch_family_name(widget.user_id);

    setState(() {
      myFamilyName = myFamilyName;
    });
  }

Future<void> _loadKidsData() async {
  debugPrint("parentDashboard - loading kids data");

  final userId = widget.user_id;
  final familyId = await FirestoreService.fetch_family_id(userId) as String;

  // Step 1: Fetch all kids in the family
  final kidsList = await FirestoreService.fetch_all_kids_by_family_id(familyId);
  debugPrint("PDashboardPage - KidsList: ${kidsList.toList().toString()}");

  final List<Map<String, dynamic>> tempKidsData = [];
  double totalDeposited = 0.0;

  // Step 2: For each kid, fetch balance and withdrawal info
  for (var kid in kidsList) {
    final kidId = kid.id;
    final kidName = kid.first_name;
    final avatarPath = kid.avatar_file_path;

    // Fetch current balance
    final paymentInfo = await FirestoreService.readKidPaymentInfo(familyId);
    final totalAmountLeft = paymentInfo?.total_amount_left ?? 0.0;

    debugPrint("parentDashboardPage - $kidName - $totalAmountLeft");

    // Fetch all withdrawals
    double totalWithdrawn = 0.0;
    final withdrawals = await FirestoreService.fetch_all_transactions_by_family_id_and_type(
      familyId,
      "withdrawal",
    );
    for (var withdrawal in withdrawals) {
      if (withdrawal.kid_id == kidId) {
        totalWithdrawn += withdrawal.amount;
      }
    }

    tempKidsData.add({
      "kid_id": kidId,
      "first_name": kidName,
      "avatar": avatarPath,
      "total_amount_left": totalAmountLeft,
      "total_withdrawn": totalWithdrawn,
    });

    totalDeposited += totalAmountLeft;
  }

  //Prevent crash if widget is disposed
  if (!mounted) return;

  setState(() {
    Kids_Data = tempKidsData;
    totalChildren = tempKidsData.length;
    totalDepositedFunds = totalDeposited;
  });

  debugPrint("PDashboardPage: KID's DATA: ${Kids_Data.toList().toString()}");
}

void _handleAddChoreSubmission(
  BuildContext context,
  String kidId,
  TextEditingController titleController,
  TextEditingController descriptionController,
  TextEditingController amountController,
  void Function(double) updateRewardMoney,
  double rewardMoney,
) async {
  final title = titleController.text.trim();
  final description = descriptionController.text.trim();

  if (title.isEmpty || description.isEmpty) {
    UtilityTopSnackBar.show(
      context: context,
      message: 'Please fill in all fields.',
      isError: true,
    );
    return;
  }

  if (rewardMoney <= 0) {
    UtilityTopSnackBar.show(
      context: context,
      message: 'Reward must be greater than 0.',
      isError: true,
    );
    return;
  }

  try {
    var uuid = Uuid();
    String customChoreId = uuid.v4();

    final chore = ChoreModel(
      id: customChoreId,
      kid_id: kidId,
      chore_title: title,
      chore_description: description,
      reward_money: rewardMoney,
      status: 'pending',
      created_at: DateTime.now(),
    );

    final docRef = await FirebaseFirestore.instance
        .collection('chores')
        .add(chore.toMap());

    await FirebaseFirestore.instance
        .collection('chores')
        .doc(docRef.id)
        .update({'id': customChoreId});

    //Increment totalDeposited to reflect locked reward
    final paymentQuery = await FirebaseFirestore.instance
    .collection('kids_payment_info')
    .where('kid_id', isEqualTo: kidId)
    .limit(1)
    .get();

    //Add locked_reward-type notification
    await FirebaseFirestore.instance.collection('kids_notifications').add({
      'type': 'locked_reward',
      'amount': rewardMoney,
      'kid_id': kidId,
      'family_id': widget.family_id, // ← access it from your state
      'notification_title': 'Pending Chore Reward',
      'notification_message':
          'Chore "$title" was set with a reward of \$${rewardMoney.toStringAsFixed(2)}.',
      'timestamp': Timestamp.now(),
    });

    UtilityTopSnackBar.show(
      context: context,
      message: 'Chore added successfully!',
      isError: false,
    );

    titleController.clear();
    descriptionController.clear();
    updateRewardMoney(0.00);
    amountController.text = "0.00";

  } catch (e) {
    UtilityTopSnackBar.show(
      context: context,
      message: 'Failed to add chore.',
      isError: true,
    );
  }
}
void showChoresModal(
    BuildContext context,
    String kidName,
    String kidId,
    String avatar,
  ) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController amountController = TextEditingController(
      text: '1.00',
    );

    double rewardMoney = 1.00;

    var messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom * 0.4,
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return Stack(
                      children: [
                        // Overlapping Image on top-right
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Image.asset(
                            avatar,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              "Chores",
                              style: GoogleFonts.fredoka(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "for $kidName",
                              style: GoogleFonts.fredoka(
                                fontSize: 24,
                                color: const Color.fromARGB(137, 0, 0, 0),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Chore Title Field
                            TextField(
                              controller: titleController,
                              decoration: InputDecoration(
                                labelText: "Chore Title",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Chore Description Field
                            TextField(
                              controller: descriptionController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: "Chore Description",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            Text(
                              "Reward Money",
                              style: GoogleFonts.fredoka(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Reward Controls
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (rewardMoney > 1) {
                                      setModalState(() {
                                        rewardMoney -= 1;
                                        amountController.text = rewardMoney
                                            .toStringAsFixed(2);
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFCA26),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(Icons.remove, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                SizedBox(
                                  width: 100,
                                  child: TextField(
                                    controller: amountController,
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: const BorderSide(
                                          color: Colors.black,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                    ),
                                    onChanged: (value) {
                                      final parsed = double.tryParse(value);
                                      if (parsed != null && parsed >= 0) {
                                        rewardMoney = parsed;
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 5),
                                InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      rewardMoney += 1;
                                      amountController.text = rewardMoney
                                          .toStringAsFixed(2);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFCA26),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(Icons.add, size: 20),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Set Button
                            ElevatedButton(
                              onPressed: () {
                                _handleAddChoreSubmission(
                                  context,
                                  kidId,  // Using kidId directly now
                                  titleController,
                                  descriptionController,
                                  amountController,
                                  (newValue) {
                                    setModalState(() {
                                      rewardMoney = newValue;
                                    });
                                  },
                                  rewardMoney,
                                );
                              },
                              style: Utilities.ourButtonStyle4(),
                              child: Text(
                                "Set",
                                style: GoogleFonts.fredoka(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

void showManageFundsModal(
  BuildContext context,
  String kidName,
  String kidId,
  String kidAvatar,
) async {
  final firestore = FirebaseFirestore.instance;

  // Fetch kids_payment_info document using `where`
  final paymentQuery = await firestore
      .collection('kids_payment_info')
      .where('kid_id', isEqualTo: kidId)
      .limit(1)
      .get();

  if (paymentQuery.docs.isEmpty) {
    UtilityTopSnackBar.show(
      context: context,
      message: "No payment info found for this kid.",
      isError: true,
    );
    return;
  }

  final paymentDoc = paymentQuery.docs.first;
  final paymentDocId = paymentDoc.id;
  final paymentData = paymentDoc.data();

  // Fetch kid document
  final kidDoc = await firestore.collection('kids').doc(kidId).get();
  final kidData = kidDoc.data();
  if (kidData == null) return;

  double totalAmountLeft = (paymentData['total_amount_left'] ?? 0).toDouble();
  final familyId = kidData['family_id'];

  final TextEditingController amountController =
      TextEditingController(text: '1.00');
  final TextEditingController messageController = TextEditingController();
  double fundAmount = 1.00;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom * 0.4,
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Manage Funds",
                                  style: GoogleFonts.fredoka(
                                    fontSize: 38,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "for $kidName",
                                  style: GoogleFonts.fredoka(
                                    fontSize: 24,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.asset(
                              kidAvatar,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Message Field
                      TextField(
                        controller: messageController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: "Message (required)",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Amount Label
                      Text(
                        "Amount (\$)",
                        style: GoogleFonts.fredoka(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Amount Input
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () {
                              if (fundAmount > 1) {
                                setModalState(() {
                                  fundAmount -= 1;
                                  amountController.text =
                                      fundAmount.toStringAsFixed(2);
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFCA26),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.black, width: 2),
                              ),
                              child: const Icon(Icons.remove, size: 20),
                            ),
                          ),
                          const SizedBox(width: 5),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              textAlign: TextAlign.center,
                              onChanged: (value) {
                                final parsed = double.tryParse(value);
                                if (parsed != null && parsed >= 0) {
                                  fundAmount = parsed;
                                }
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          InkWell(
                            onTap: () {
                              setModalState(() {
                                fundAmount += 1;
                                amountController.text =
                                    fundAmount.toStringAsFixed(2);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFCA26),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.black, width: 2),
                              ),
                              child: const Icon(Icons.add, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Deposit
                          ElevatedButton(
                            style: Utilities.depositButtonStyle(),
                            onPressed: () async {
                              if (messageController.text.trim().isEmpty) {
                                UtilityTopSnackBar.show(
                                  context: context,
                                  message: "Message is required",
                                  isError: true,
                                );
                                return;
                              }
                              if (fundAmount <= 0) {
                                UtilityTopSnackBar.show(
                                  context: context,
                                  message: "Enter a valid deposit amount",
                                  isError: true,
                                );
                                return;
                              }

                              await firestore
                                  .collection('kids_payment_info')
                                  .doc(paymentDocId)
                                  .update({
                                'total_amount_left':
                                    FieldValue.increment(fundAmount),
                                'totalDeposited':
                                    FieldValue.increment(fundAmount),
                              });

                              await firestore
                                  .collection('kids_notifications')
                                  .add({
                                'family_id': familyId,
                                'kid_id': kidId,
                                'notification_title': 'Funds Deposited',
                                'notification_message':
                                    messageController.text.trim(),
                                'type': 'deposit',
                                'amount': fundAmount,
                                'created_at': FieldValue.serverTimestamp(),
                              });

                              UtilityTopSnackBar.show(
                                context: context,
                                message:
                                    "\$${fundAmount.toStringAsFixed(2)} deposited successfully",
                              );

                              Navigator.pop(context);
                            },
                            child: Text(
                              "Deposit",
                              style: GoogleFonts.fredoka(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),

                          // Withdraw
                          ElevatedButton(
                            style: Utilities.withdrawButtonStyle(),
                            onPressed: () async {
                              if (messageController.text.trim().isEmpty) {
                                UtilityTopSnackBar.show(
                                  context: context,
                                  message: "Message is required",
                                  isError: true,
                                );
                                return;
                              }
                              if (fundAmount <= 0) {
                                UtilityTopSnackBar.show(
                                  context: context,
                                  message: "Enter a valid withdrawal amount",
                                  isError: true,
                                );
                                return;
                              }
                              if (fundAmount > totalAmountLeft) {
                                UtilityTopSnackBar.show(
                                  context: context,
                                  message: "Insufficient balance",
                                  isError: true,
                                );
                                return;
                              }

                              await firestore
                                  .collection('kids_payment_info')
                                  .doc(paymentDocId)
                                  .update({
                                'total_amount_left':
                                    FieldValue.increment(-fundAmount),
                                'totalWithdrawn':
                                    FieldValue.increment(fundAmount),
                              });

                              await firestore
                                  .collection('kids_notifications')
                                  .add({
                                'family_id': familyId,
                                'kid_id': kidId,
                                'notification_title': 'Funds Withdrawn',
                                'notification_message':
                                    messageController.text.trim(),
                                'type': 'withdraw',
                                'amount': fundAmount,
                                'created_at': FieldValue.serverTimestamp(),
                              });

                              UtilityTopSnackBar.show(
                                context: context,
                                message:
                                    "\$${fundAmount.toStringAsFixed(2)} withdrawn successfully",
                              );

                              Navigator.pop(context);
                            },
                            child: Text(
                              "Withdraw",
                              style: GoogleFonts.fredoka(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}
  // BUILD Function:
@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: false, // Prevent back navigation
    onPopInvokedWithResult: (didPop, result) async {
      // Do nothing when back is pressed
    },
    child: Scaffold(
      drawer: ParentDrawer(
        selectedPage: 'dashboard',
        familyName: myFamilyName,
        user_id: widget.user_id,
        parentId: widget.parent_id,
        family_id: widget.family_id,
      ),
      backgroundColor: const Color(0xFFFFCA26),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFCA26),
        elevation: 0,
        title: Text(
          "KidsBank",
          style: GoogleFonts.fredoka(
            fontSize: 44,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 12, right: 4, top: 5, bottom: 10),
            child: InkWell(
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.menu, color: Color(0xFFFFCA26)),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // TOP - Overview Card
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 300,
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCA26),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 160), // space for image
                      
                      // Live total deposited
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('kids_notifications')
                            .where('family_id', isEqualTo: familyId)
                            .where('type', whereIn: ['locked_reward', 'deposit']) // COMBINED TYPES
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Text(
                              "\$0.00",
                              style: GoogleFonts.fredoka(fontSize: 46, fontWeight: FontWeight.bold),
                            );
                          }

                          double totalDepositedFunds = snapshot.data!.docs.fold(0.0, (total, doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final amount = (data['amount'] ?? 0).toDouble();
                            return total + amount;
                          });

                          return Text(
                            "\$${totalDepositedFunds.toStringAsFixed(2)}",
                            style: GoogleFonts.fredoka(fontSize: 46, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                      Text(
                        "Total Deposited Funds",
                        style: GoogleFonts.fredoka(fontSize: 17.3, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 12,
                  child: Image.asset('assets/pig.png', width: 150),
                ),
                Positioned(
                  top: 60,
                  right: 70,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Children",
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "$totalChildren",
                        style: GoogleFonts.fredoka(
                          fontSize: 90.2,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // KIDS INFO Section
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFE6E8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      "Kid's Info",
                      style: GoogleFonts.fredoka(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Kid's List
                    Expanded(
                      child: ListView.builder(
                        itemCount: Kids_Data.length,
                        itemBuilder: (context, index) {
                          final kid = Kids_Data[index];
                          final kidId = kid['kid_id'];
                          final kidName = kid['first_name'];
                          final kidAvatar = kid['avatar'];
                          final tileColor = tileColors[index % tileColors.length];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: tileColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Avatar
                                CircleAvatar(
                                  backgroundImage: AssetImage(kidAvatar),
                                  radius: 24,
                                ),
                                const SizedBox(width: 12),

                                // Name & Balance
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        kidName,
                                        style: GoogleFonts.fredoka(
                                          fontSize: 23,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('kids_payment_info')
                                            .where('kid_id', isEqualTo: kidId)
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          double currentBalance = 0.0;

                                          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                                            final doc = snapshot.data!.docs.first;
                                            final paymentData = doc.data() as Map<String, dynamic>;
                                            currentBalance = (paymentData['total_amount_left'] ?? 0.0).toDouble();
                                          }

                                          return Text(
                                            "\$${currentBalance.toStringAsFixed(2)}",
                                            style: GoogleFonts.fredoka(
                                              fontSize: 23,
                                              color: Colors.black87,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Buttons
                                Column(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        if (kidId == null || kidName == null || kidAvatar == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Missing kid information")),
                                          );
                                          return;
                                        }
                                        showManageFundsModal(context, kidName, kidId, kidAvatar);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFFCA26),
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                                        side: const BorderSide(color: Colors.black, width: 2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        "Manage Funds",
                                        style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    OutlinedButton(
                                      onPressed: () {
                                        if (kidId == null || kidName == null || kidAvatar == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Missing kid information")),
                                          );
                                          return;
                                        }
                                        showChoresModal(context, kidName, kidId, kidAvatar);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        side: const BorderSide(color: Colors.black, width: 2),
                                        padding: const EdgeInsets.symmetric(horizontal: 33, vertical: 1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        "Chores",
                                        style: GoogleFonts.fredoka(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
