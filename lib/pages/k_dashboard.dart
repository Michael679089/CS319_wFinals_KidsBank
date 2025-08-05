import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/notifications_model.dart';
import 'package:wfinals_kidsbank/utilities/utilities.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class KidsDashboard extends StatefulWidget {
  final String kidId;
  final String familyUserId;
  final String? familyName; // Added for consistency
  final bool there_are_parent_in_family;

  const KidsDashboard({
    super.key,
    required this.kidId,
    required this.familyUserId,
    this.familyName,
    this.there_are_parent_in_family = false,
  });

  @override
  State<KidsDashboard> createState() => _KidsDashboardState();
}

class _KidsDashboardState extends State<KidsDashboard> {
  String kidName = '';
  double balance = 0.0;
  bool isLoading = true;
  String? errorMessage;
  late bool thereAreParents;

  // for navigation:
@override
void initState() {
  super.initState();
  thereAreParents = widget.there_are_parent_in_family;
  UtilitiesKidsDashboardNavigation.currentPageIndex = 0;
  UtilitiesKidsDashboardNavigation.selectedPage = "dashboard";
  fetchKidInfo();
}

Future<void> fetchKidInfo() async {
  try {
    debugPrint("Fetching kid info for kidId: ${widget.kidId}");

    // Fetch kid profile
    final kidSnapshot = await FirebaseFirestore.instance
        .collection('kids')
        .doc(widget.kidId)
        .get();

    if (!kidSnapshot.exists) {
      throw Exception('Kid profile not found');
    }

    // Fetch payment info by kid_id
    final paymentQuery = await FirebaseFirestore.instance
        .collection('kids_payment_info')
        .where('kid_id', isEqualTo: widget.kidId)
        .limit(1)
        .get();

    double fetchedBalance = 0.0;
    if (paymentQuery.docs.isNotEmpty) {
      final paymentData = paymentQuery.docs.first.data();
      debugPrint("paymentData: $paymentData");

      final rawValue = paymentData['total_amount_left'];
      if (rawValue is int) {
        fetchedBalance = rawValue.toDouble();
      } else if (rawValue is double) {
        fetchedBalance = rawValue;
      } else {
        debugPrint("total_amount_left is not numeric: $rawValue");
      }
    } else {
      debugPrint("No payment info found for this kid.");
    }

    setState(() {
      kidName = kidSnapshot.data()!['first_name'] ?? 'Unknown';
      balance = fetchedBalance;
      isLoading = false;
    });

    debugPrint("Final balance set to: $balance");
  } catch (e) {
    setState(() {
      isLoading = false;
      errorMessage = 'Failed to load kid info: $e';
    });
    debugPrint("Error: $e");
     UtilityTopSnackBar.show( context: context, message:'Error: $e', isError: true);
  }
}
  Stream<List<Map<String, dynamic>>> getChoresStream() {
  return FirebaseFirestore.instance
      .collection('chores')
      .where('kid_id', isEqualTo: widget.kidId) // Changed from 'kidId' to 'kid_id'
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['chore_title'] ?? 'No Title',
              'description': data['chore_description'] ?? 'No Description',
              'price': (data['reward_money'] as num?)?.toDouble() ?? 0.0,
              'status': data['status'] ?? 'pending',
              'created_at': data['created_at']?.toDate(),
            };
          }).toList());
}
  Future<void> markChoreAsCompleted(String choreId, String title) async {
    try {
      await FirebaseFirestore.instance.collection('chores').doc(choreId).update(
        {'status': 'completed'},
      );

      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'chore_completed',
        'kid_id': widget.kidId,
        'kid_name': kidName,
        'chore_title': title,
        'timestamp': FieldValue.serverTimestamp(),
      });

       UtilityTopSnackBar.show(
          context: context,
          message: "✔️ \"$title\" marked as completed!",
          isError: false,
        );
    } catch (e) {
      UtilityTopSnackBar.show(
        context: context,
        message:"Failed to mark chore as completed: $e",
        isError: true,
      );
    }
  }

void _showWithdrawModal(QueryDocumentSnapshot paymentDoc) {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController(text: "1.00");

  double withdrawAmount = 1.0;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('kids_payment_info')
                  .where('kid_id', isEqualTo: widget.kidId)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text("No payment info found.",
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center);
                }

                final liveDoc = snapshot.data!.docs.first;
                final liveBalance =
                    (liveDoc['total_amount_left'] ?? 0).toDouble();

                return StatefulBuilder(
                  builder: (context, setModalState) {
                    // Check if submit should be locked (only amount check)
                    bool isSubmitLocked =
                        withdrawAmount <= 0 || withdrawAmount > liveBalance;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Withdraw Money",
                            style: GoogleFonts.fredoka(
                                fontSize: 24, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),

                        // Title
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                              hintText: "Reason for withdrawal",
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide:
                                      const BorderSide(color: Colors.black))),
                        ),
                        const SizedBox(height: 10),

                        // Description
                        TextField(
                          controller: descriptionController,
                          maxLines: 2,
                          decoration: InputDecoration(
                              hintText: "Description",
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide:
                                      const BorderSide(color: Colors.black))),
                        ),
                        const SizedBox(height: 20),

                        // Amount controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                if (withdrawAmount > 1) {
                                  setModalState(() {
                                    withdrawAmount -= 1;
                                    amountController.text =
                                        withdrawAmount.toStringAsFixed(2);
                                  });
                                }
                              },
                              icon: const Icon(Icons.remove, size: 20),
                              style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFCA26),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(
                                          color: Colors.black, width: 2))),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: const BorderSide(
                                            color: Colors.black)),
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 8)),
                                style: GoogleFonts.fredoka(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                                onChanged: (value) {
                                  double? parsed = double.tryParse(value);
                                  setModalState(() {
                                    if (parsed != null) {
                                      withdrawAmount = parsed;
                                    } else {
                                      withdrawAmount = 0;
                                    }
                                    //Update submit lock dynamically on input
                                    isSubmitLocked = withdrawAmount <= 0 || withdrawAmount > liveBalance;
                                  });
                                },
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}$'))
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: withdrawAmount < liveBalance
                                  ? () {
                                      setModalState(() {
                                        withdrawAmount += 1;
                                        if (withdrawAmount > liveBalance) {
                                          withdrawAmount = liveBalance;
                                        }
                                        amountController.text =
                                            withdrawAmount.toStringAsFixed(2);
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.add, size: 20),
                              style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFCA26),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(
                                          color: Colors.black, width: 2))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Cancel",
                                  style: GoogleFonts.fredoka(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red)),
                            ),
                            ElevatedButton(
                            onPressed: isSubmitLocked
                                ? null
                                : () async {
                                    final title = titleController.text.trim();
                                    final desc = descriptionController.text.trim();

                                    //Text fields check (snack only, no lock)
                                    if (title.isEmpty || desc.isEmpty) {
                                      UtilityTopSnackBar.show(
                                        context: context,
                                        message: "Please fill all the fields.",
                                        isError: true,
                                      );
                                      return;
                                    }

                                    try {
                                      await FirebaseFirestore.instance.runTransaction((transaction) async {
                                        final freshSnap = await transaction.get(liveDoc.reference);
                                        final currentBal =
                                            (freshSnap['total_amount_left'] ?? 0).toDouble();
                                        if (withdrawAmount > currentBal) {
                                          throw Exception("Insufficient funds.");
                                        }
                                        transaction.update(liveDoc.reference, {
                                          'total_amount_left': FieldValue.increment(-withdrawAmount),
                                          'totalWithdrawn': FieldValue.increment(withdrawAmount),
                                        });
                                      });

                                      await FirebaseFirestore.instance.collection('kids_notifications').add({
                                        'kid_id': widget.kidId,
                                        'notification_title': title,
                                        'notification_message': desc,
                                        'amount': withdrawAmount,
                                        'type': 'withdrawal',
                                        'timestamp': FieldValue.serverTimestamp(),
                                      });

                                      //Show snack immediately
                                      UtilityTopSnackBar.show(
                                        context: context,
                                        message:
                                            "Withdrawal of \$${withdrawAmount.toStringAsFixed(2)} submitted!",
                                        isError: false,
                                      );

                                      //Store a safe context before closing the modal
                                      final safeContext = context;

                                      //Wait before closing modal (so snack is visible)
                                      await Future.delayed(const Duration(seconds: 1));
                                      Navigator.pop(context);

                                      //Check latest balance
                                      final latestSnap = await FirebaseFirestore.instance
                                          .collection('kids_payment_info')
                                          .doc(liveDoc.id)
                                          .get();
                                      final latestBalance =
                                          (latestSnap['total_amount_left'] ?? 0).toDouble();

                                     //Show prompt if balance is 0
                                      if (latestBalance <= 0) {
                                        Future.delayed(const Duration(seconds: 3), () {
                                          showDialog(
                                            context: safeContext, // Use saved context
                                            barrierDismissible: false,
                                            builder: (ctx) => AlertDialog(
                                              title: Text(
                                                "Balance Update",
                                                style: GoogleFonts.fredoka(
                                                    fontSize: 24, fontWeight: FontWeight.bold),
                                              ),
                                              content: Text(
                                                "You now have no current balance after withdrawing all.",
                                                style: GoogleFonts.fredoka(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red),
                                                textAlign: TextAlign.center,
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(ctx).pop(),
                                                  child: Text(
                                                    "OK",
                                                    style: GoogleFonts.fredoka(
                                                        fontSize: 18, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        });
                                      }
                                    } catch (e) {
                                      UtilityTopSnackBar.show(
                                        context: context,
                                        message: "Failed to process withdrawal: $e",
                                        isError: true,
                                      );
                                    }
                                  },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF60C56F),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      side: const BorderSide(
                                          color: Colors.black, width: 2))),
                              child: Text("Submit",
                                  style: GoogleFonts.fredoka(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
    },
  );
}
  
@override
Widget build(BuildContext context) {
  var navigator = Navigator.of(context);

  return PopScope(
    canPop: true,
    onPopInvokedWithResult: (didPop, result) async {
      if (!didPop) {
        Navigator.pushReplacementNamed(
          context,
          '/account-selector-page',
          arguments: {
            "user-id": widget.familyUserId,
            "there-are-parent-in-family": widget.there_are_parent_in_family,
          },
        );
      }
    },
    child: Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          UtilitiesKidsDashboardNavigation.handleKidDashboardNavigationBottomBar(
            index: index,
            kidId: widget.kidId,
            familyUserId: widget.familyUserId,
            context: context,
          );
        },
        selectedIndex: UtilitiesKidsDashboardNavigation.currentPageIndex,
        backgroundColor: const Color.fromARGB(255, 253, 99, 39),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(color: Colors.white),
        ),
        destinations: UtilitiesKidsDashboardNavigation.myDestinations,
      ),
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFFCA26),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          errorMessage!,
                          style: GoogleFonts.fredoka(
                            fontSize: 20,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: fetchKidInfo,
                          child: Text(
                            'Retry',
                            style: GoogleFonts.fredoka(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Hello, $kidName${widget.familyName != null ? ' from ${widget.familyName}' : ''}",
                                  style: GoogleFonts.fredoka(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                return GestureDetector(
                                  onTap: () => Scaffold.of(context).openDrawer(),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/hamburger_icon.png',
                                        height: 50,
                                        width: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFAEDDFF),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: Colors.black, width: 3),
                          ),
                          child: Column(
                            children: [
                              Image.asset('assets/piggy_bank.png', height: 100),
                              const SizedBox(height: 10),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('kids_payment_info')
                                    .where('kid_id', isEqualTo: widget.kidId)
                                    .limit(1)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const CircularProgressIndicator();
                                  }

                                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                    return Text(
                                      "\$0.00",
                                      style: GoogleFonts.fredoka(
                                        fontSize: 50,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    );
                                  }

                                  final doc = snapshot.data!.docs.first;
                                  final data = doc.data() as Map<String, dynamic>;
                                  final balance = (data['total_amount_left'] ?? 0).toDouble();

                                  return Text(
                                    "\$${balance.toStringAsFixed(2)}",
                                    style: GoogleFonts.fredoka(
                                      fontSize: 50,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                navigator.pushReplacementNamed(
                                  "/kids-chores-page",
                                  arguments: {
                                    "kid-id": widget.kidId,
                                    "family-user-id": widget.familyUserId,
                                  },
                                );
                                UtilitiesKidsDashboardNavigation
                                    .currentPageIndex = 1;
                                UtilitiesKidsDashboardNavigation.selectedPage =
                                    "chores";
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF927BD9),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                "Chores",
                                style: GoogleFonts.fredoka(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('kids_payment_info')
                                  .where('kid_id', isEqualTo: widget.kidId)
                                  .limit(1)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                double liveBalance = 0.0;

                                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                                  final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                                  liveBalance = (data['total_amount_left'] ?? 0).toDouble();
                                }

                                return ElevatedButton(
                                  onPressed: liveBalance <= 0
                                      ? null
                                      : () => _showWithdrawModal(snapshot.data!.docs.first),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        liveBalance <= 0 ? Colors.grey : const Color(0xFFFD6327),
                                    padding: const EdgeInsets.symmetric(horizontal: 65, vertical: 20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: const BorderSide(color: Colors.black, width: 2),
                                    ),
                                  ),
                                  child: Text(
                                    "Withdraw",
                                    style: GoogleFonts.fredoka(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Chores",
                          style: GoogleFonts.fredoka(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: StreamBuilder<List<Map<String, dynamic>>>(
                            stream: getChoresStream(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Error loading chores: ${snapshot.error}',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 20,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Center(
                                  child: Text(
                                    "No chores assigned yet!",
                                    style: GoogleFonts.fredoka(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }

                              final chores = snapshot.data!;
                              final pendingChores = chores.where((c) => c['status'] == 'pending').toList();

                              if (pendingChores.isEmpty) {
                                return Center(
                                  child: Text(
                                    "No pending chores!",
                                    style: GoogleFonts.fredoka(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }

                              return ListView.builder(
                                itemCount: pendingChores.length,
                                itemBuilder: (context, index) {
                                  final chore = pendingChores[index];
                                  return GestureDetector(
                                    onTap: () => _showMarkAsCompletePrompt(context, chore),
                                    child: SizedBox(
                                      height: 90,
                                      child: Card(
                                        color: const Color(0xFFEFE6E8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          side: const BorderSide(color: Colors.black, width: 2),
                                        ),
                                        margin: const EdgeInsets.symmetric(vertical: 6),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.task_alt,
                                                color: Colors.green,
                                                size: 30,
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      chore['title'],
                                                      style: GoogleFonts.fredoka(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      chore['description'],
                                                      style: GoogleFonts.inter(fontSize: 12),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    if (chore['created_at'] != null)
                                                      Text(
                                                        'Created: ${DateFormat('MMM dd, yyyy').format(chore['created_at'])}',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 10,
                                                          color: Colors.grey[700],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFAEDDFF),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Colors.black, width: 2),
                                                ),
                                                child: Text(
                                                  "\$${chore['price'].toStringAsFixed(2)}",
                                                  style: GoogleFonts.fredoka(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    ),
  );
}

// Function to show the "Mark as Complete" dialog
void _showMarkAsCompletePrompt(BuildContext context, Map<String, dynamic> chore) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          "Mark Chore as Complete?",
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to mark '${chore['title']}' as completed?",
          style: GoogleFonts.fredoka(),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              "Cancel",
              style: GoogleFonts.fredoka(color: Colors.red),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text(
              "Complete",
              style: GoogleFonts.fredoka(color: Colors.green),
            ),
            onPressed: () {
              // Call the function to update the chore status in the database
              markChoreAsCompleted(chore['id'], chore['title']);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
  }
}