import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/chores_model.dart';
import 'package:wfinals_kidsbank/database/models/kid_model.dart';
import 'package:wfinals_kidsbank/database/models/kid_payment_info.dart';
import 'package:wfinals_kidsbank/database/models/notifications_model.dart';
import 'package:wfinals_kidsbank/pages/p_dashboard_drawer.dart';
import 'package:flutter/services.dart';
import 'package:wfinals_kidsbank/utilities/utilities.dart';

class ParentDashboard extends StatefulWidget {
  final String familyUserId;

  final String parentId;

  const ParentDashboard({
    super.key,
    required this.familyUserId,
    required this.parentId,
  });

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

double totalDepositedFunds = 0.0;

class _ParentDashboardState extends State<ParentDashboard> {
  List<Map<String, dynamic>> kidsData = [];
  int totalChildren = 0;
  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final List<Color> tileColors = [
    const Color.fromARGB(255, 252, 193, 220),
    const Color.fromARGB(255, 209, 241, 212),
    const Color.fromARGB(255, 251, 194, 215),
    const Color.fromARGB(255, 224, 182, 238),
    const Color.fromARGB(255, 240, 217, 233),
  ];

  FirestoreService myFirestoreService = FirestoreService();

  String myFamilyName = "";

  // The INITSTATE Function

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadKidsData();
      _loadMyFamilyData();
    });
  }

  // Other Functions:

  void _loadMyFamilyData() async {
    myFamilyName = await myFirestoreService.getFamilyName(widget.familyUserId);

    setState(() {
      myFamilyName = myFamilyName;
    });
  }

  Future<void> _loadKidsData() async {
    // In this function it looks like we need to get the name, the avatar path, and the available balance the user has.
    debugPrint("parentDashboard - loading kids data");
    var familyId = widget.familyUserId;

    // Step 1: Get list of kid models
    List<KidModel> listOfKidModel = await myFirestoreService
        .getKidsByFamilyUserId(familyId);

    List<Map<String, dynamic>> tempKidsData = [];

    double runningTotal = 0.0;

    // Step 2: Get the balance in each kid.
    for (var kid in listOfKidModel) {
      final kidId = kid.kidId;

      // 2 Get usableBalance
      var kidPaymentInfoSnapshot = await FirebaseFirestore.instance
          .collection('kidPaymentInfo')
          .where("kidId", isEqualTo: kidId)
          .get();
      KidsPaymentInfoModel balanceModel = KidsPaymentInfoModel.fromMap(
        kidPaymentInfoSnapshot.docs.first.data(),
      );
      var usableBalance = int.parse(balanceModel.amountLeft as String);
      debugPrint(
        "parentDashboardPage - ${balanceModel.kidId} - ${balanceModel.amountLeft}",
      );

      // 2 Get total withdrawals for this kid
      bool doesNotificationsExist = await myFirestoreService
          .checkIfTableCollectionExist("notifications");

      double totalWithdrawn = 0.0;
      if (doesNotificationsExist) {
        final withdrawalsSnapshot = await FirebaseFirestore.instance
            .collection('notifications')
            .where('kidId', isEqualTo: kidId)
            .where('type', isEqualTo: 'withdrawal')
            .get();

        for (var withdrawalDoc in withdrawalsSnapshot.docs) {
          totalWithdrawn += (withdrawalDoc.data()['amount'] ?? 0.0);
        }
      }

      // 2 Total deposited = usable_balance + total withdrawals
      final totalDeposited = usableBalance + totalWithdrawn;

      runningTotal += totalDeposited;

      tempKidsData.add({
        "id": kid.kidId,
        "name": kid.firstName,
        "avatar": kid.avatarFilePath,
        "balance": usableBalance,
      });
    }

    setState(() {
      kidsData = tempKidsData;
      totalChildren = tempKidsData.length;
      totalDepositedFunds = runningTotal;
    });
  }

  void _handleAddChoreSubmission(
    String kidId,
    TextEditingController titleController,
    TextEditingController descriptionController,
    double rewardMoney,
    messenger,
  ) async {
    debugPrint("parentDashboardPage - called chore submission");
    final String choreTitle = titleController.text.trim();
    final String choreDescription = descriptionController.text.trim();

    if (choreTitle.isEmpty || choreDescription.isEmpty || rewardMoney <= 0) {
      Utilities.invokeTopSnackBar(
        "Please fill in all fields and set a valid reward.",
        context,
      );
      return;
    }

    ChoreModel newPendingChoreModel = ChoreModel(
      kidId: kidId,
      choreTitle: choreTitle,
      choreDesc: choreDescription,
      rewardMoney: rewardMoney,
      status: "pending",
    );
    myFirestoreService.addChoreToChoresCollection(newPendingChoreModel);

    // ignore: use_build_context_synchronously
    Navigator.pop(context);

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(this.context).showSnackBar(
      const SnackBar(
        content: Text("Chore created successfully!"),
        backgroundColor: Colors.green,
      ),
    );
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
                              onPressed: () => _handleAddChoreSubmission(
                                kidId,
                                titleController,
                                descriptionController,
                                rewardMoney,
                                messenger,
                              ),

                              style: Utilities().ourButtonStyle1(),
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
    String avatar,
  ) {
    final TextEditingController messageController = TextEditingController();
    final TextEditingController amountController = TextEditingController(
      text: '1.00',
    );
    double fundAmount = 1.00;

    var navigator = Navigator.of(context);
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
                              "Manage Funds",
                              style: GoogleFonts.fredoka(
                                fontSize: 30,
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
                            const SizedBox(height: 20),

                            // Fund Amount Controls
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (fundAmount > 1) {
                                      setModalState(() {
                                        fundAmount -= 1;
                                        amountController.text = fundAmount
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
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    textAlign: TextAlign.center,
                                    autofocus: false,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                    ),
                                    onChanged: (value) {
                                      final parsed = double.tryParse(value);
                                      if (parsed != null && parsed >= 0) {
                                        fundAmount = parsed;
                                      } else if (value.isNotEmpty) {
                                        setModalState(() {
                                          fundAmount = 0;
                                        });
                                      }
                                    },
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      fundAmount += 1;
                                      amountController.text = fundAmount
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

                            // Message Field
                            TextField(
                              controller: messageController,
                              autofocus: true, // 🔥 Auto-focus here
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: "Message for Kid",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Deposit and Withdraw Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final String message = messageController
                                          .text
                                          .trim();
                                      if (message.isEmpty || fundAmount <= 0) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "⚠️ Enter a message and valid amount.",
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      try {
                                        final docRef = FirebaseFirestore
                                            .instance
                                            .collection('kidPaymentInfo')
                                            .doc(kidId);

                                        final docSnapshot = await docRef.get();
                                        double currentBalance = 0;
                                        if (docSnapshot.exists) {
                                          currentBalance =
                                              (docSnapshot.data()?['usable_balance'] ??
                                                      0)
                                                  .toDouble();
                                        }

                                        final newBalance =
                                            currentBalance + fundAmount;

                                        // Update balance
                                        await docRef.set({
                                          'usable_balance': newBalance,
                                          'last_updated':
                                              FieldValue.serverTimestamp(),
                                        });

                                        debugPrint(
                                          "parentDashboardPage - add deposit notification",
                                        );

                                        // Push notification
                                        NotificationsModel newNotification =
                                            NotificationsModel(
                                              familyId: widget.familyUserId,
                                              kidId: kidId,
                                              title: message,
                                              message: message,
                                              type: 'deposit',
                                            );
                                        await myFirestoreService
                                            .addNotificationToNotificationCollections(
                                              newNotification,
                                            );

                                        navigator.pop();
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "✅ Deposited \$${fundAmount.toStringAsFixed(2)} successfully!",
                                              style: GoogleFonts.fredoka(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (e) {
                                        debugPrint("Error during deposit: $e");
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "❌ Failed to deposit funds.",
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF60C56F),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        side: const BorderSide(
                                          color: Colors.black,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      "Deposit",
                                      style: GoogleFonts.fredoka(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final String message = messageController
                                          .text
                                          .trim();
                                      if (message.isEmpty || fundAmount <= 0) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "⚠️ Enter a message and valid amount.",
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      try {
                                        final docRef = FirebaseFirestore
                                            .instance
                                            .collection('kids_payment_info')
                                            .doc(kidId);

                                        final docSnapshot = await docRef.get();
                                        double currentBalance = 0;
                                        if (docSnapshot.exists) {
                                          currentBalance =
                                              (docSnapshot.data()?['usable_balance'] ??
                                                      0)
                                                  .toDouble();
                                        }

                                        if (fundAmount > currentBalance) {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "❌ Insufficient balance for withdrawal.",
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        final newBalance =
                                            currentBalance - fundAmount;

                                        // Update balance
                                        await docRef.set({
                                          'usable_balance': newBalance,
                                          'last_updated':
                                              FieldValue.serverTimestamp(),
                                        });

                                        // Push notification
                                        NotificationsModel
                                        withdrawalNotification =
                                            NotificationsModel(
                                              familyId: widget.familyUserId,
                                              kidId: kidId,
                                              title: message,
                                              type: 'withdrawal',
                                            );
                                        myFirestoreService
                                            .addNotificationToNotificationCollections(
                                              withdrawalNotification,
                                            );

                                        navigator.pop();
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "✅ Withdrew \$${fundAmount.toStringAsFixed(2)} successfully!",
                                              style: GoogleFonts.fredoka(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (e) {
                                        debugPrint(
                                          "Error during withdrawal: $e",
                                        );
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "❌ Failed to withdraw funds.",
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFEB40D),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        side: const BorderSide(
                                          color: Colors.black,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      "Withdraw",
                                      style: GoogleFonts.fredoka(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
          familyUserId: widget.familyUserId,
          parentId: widget.parentId,
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
              padding: const EdgeInsets.only(
                left: 12,
                right: 4,
                top: 5,
                bottom: 10,
              ),
              child: InkWell(
                onTap: () {
                  Scaffold.of(context).openDrawer(); // Opens drawer if added
                },
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black, // Black circle background
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.menu,
                    color: Color(
                      0xFFFFCA26,
                    ), // Yellow icon (same as background)
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Top Overview Card
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
                        Text(
                          "\$${totalDepositedFunds.toStringAsFixed(2)}", // Static placeholder
                          style: GoogleFonts.fredoka(
                            fontSize: 46,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          "Total Deposited Funds",
                          style: GoogleFonts.fredoka(
                            fontSize: 17.3,
                            color: Colors.black,
                          ),
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

              // Kids Info Section
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
                      Text(
                        "Kid's Info",
                        style: GoogleFonts.fredoka(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: kidsData.length,
                          itemBuilder: (context, index) {
                            final kid = kidsData[index];
                            final kidId = kid['id'];
                            final kidName = kid['name'];
                            final kidAvatar = kid['avatar'];
                            final tileColor =
                                tileColors[index % tileColors.length];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: tileColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: AssetImage(kid['avatar']),
                                    radius: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          kid['name'],
                                          style: GoogleFonts.fredoka(
                                            fontSize: 23,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "\$${kid['balance'].toStringAsFixed(2)}",
                                          style: GoogleFonts.fredoka(
                                            fontSize: 23,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          if (kidId == null ||
                                              kidName == null ||
                                              kidAvatar == null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Missing kid information",
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          showManageFundsModal(
                                            context,
                                            kidName,
                                            kidId,
                                            kidAvatar,
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFFFCA26,
                                          ),
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 15,
                                            vertical: 2,
                                          ),
                                          side: const BorderSide(
                                            color: Colors.black,
                                            width: 2,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          "Manage Funds",
                                          style: GoogleFonts.fredoka(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      OutlinedButton(
                                        onPressed: () {
                                          if (kidId == null ||
                                              kidName == null ||
                                              kidAvatar == null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Missing kid information",
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          showChoresModal(
                                            context,
                                            kidName,
                                            kidId,
                                            kidAvatar,
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          side: const BorderSide(
                                            color: Colors.black,
                                            width: 2,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 33,
                                            vertical: 1,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
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
