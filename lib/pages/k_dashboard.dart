import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/notifications_model.dart';
import 'package:wfinals_kidsbank/utilities/utilities.dart';

class KidsDashboard extends StatefulWidget {
  final String kidId;
  final String familyUserId;
  final String? familyName; // Added for consistency

  const KidsDashboard({
    super.key,
    required this.kidId,
    required this.familyUserId,
    this.familyName,
  });

  @override
  State<KidsDashboard> createState() => _KidsDashboardState();
}

class _KidsDashboardState extends State<KidsDashboard> {
  String kidName = '';
  double balance = 0.0;
  bool isLoading = true;
  String? errorMessage;

  // for navigation:
  @override
  void initState() {
    super.initState();
    fetchKidInfo();

    UtilitiesKidsDashboardNavigation.currentPageIndex =
        0; // Restart it to zero if user comes back.
    UtilitiesKidsDashboardNavigation.selectedPage =
        "dashboard"; // Restart it if user comes back.
  }

  Future<void> fetchKidInfo() async {
    try {
      // Batch fetch kid and payment info
      final kidDoc = FirebaseFirestore.instance
          .collection('kids')
          .doc(widget.kidId);
      final paymentDoc = FirebaseFirestore.instance
          .collection('kids_payment_info')
          .doc(widget.kidId);

      final results = await Future.wait([kidDoc.get(), paymentDoc.get()]);

      final kidSnapshot = results[0];
      final paymentSnapshot = results[1];

      if (!kidSnapshot.exists) {
        throw Exception('Kid profile not found');
      }

      setState(() {
        kidName = kidSnapshot.data()!['firstName'] ?? 'Unknown';
        balance = paymentSnapshot.exists
            ? (paymentSnapshot['usable_balance']?.toDouble() ?? 0.0)
            : 0.0;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load kid info: $e';
      });
      showCustomSnackBar('Error: $e', isError: true);
    }
  }

  Stream<List<Map<String, dynamic>>> getChoresStream() {
    return FirebaseFirestore.instance
        .collection('chores')
        .where('kidId', isEqualTo: widget.kidId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              'title': doc['chore_title'],
              'description': doc['chore_desc'],
              'price': doc['reward_money']?.toDouble() ?? 0.0,
              'status': doc['status'],
            };
          }).toList(),
        );
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

      showCustomSnackBar("✅ \"$title\" marked as completed!", isError: false);
    } catch (e) {
      showCustomSnackBar(
        "Failed to mark chore as completed: $e",
        isError: true,
      );
    }
  }

  void showCustomSnackBar(String message, {bool isError = false}) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: GoogleFonts.fredoka(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showWithdrawModal() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    double withdrawAmount = 1.0;

    showDialog(
      context: context,
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Withdraw Money',
                          style: GoogleFonts.fredoka(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: "Reason for withdrawal",
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: descriptionController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: "Description",
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                if (withdrawAmount > 1) {
                                  setModalState(() => withdrawAmount -= 1);
                                }
                              },
                              icon: const Icon(Icons.remove, size: 20),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFFFCA26),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                "\$${withdrawAmount.toStringAsFixed(2)}",
                                style: GoogleFonts.fredoka(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: () =>
                                  setModalState(() => withdrawAmount += 1),
                              icon: const Icon(Icons.add, size: 20),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFFFCA26),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.fredoka(
                                  fontSize: 18,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final title = titleController.text.trim();
                                final desc = descriptionController.text.trim();

                                if (title.isEmpty ||
                                    desc.isEmpty ||
                                    withdrawAmount <= 0) {
                                  showCustomSnackBar(
                                    "Please fill all fields and enter a valid amount.",
                                    isError: true,
                                  );
                                  return;
                                }

                                if (withdrawAmount > balance) {
                                  showCustomSnackBar(
                                    "Cannot withdraw more than your balance (\$${balance.toStringAsFixed(2)}).",
                                    isError: true,
                                  );
                                  return;
                                }

                                try {
                                  await FirebaseFirestore.instance
                                      .collection('kidsPaymentInfo')
                                      .doc(widget.kidId)
                                      .update({
                                        'usableBalance': FieldValue.increment(
                                          -withdrawAmount,
                                        ),
                                      });

                                  NotificationsModel withdrawalKidNotification =
                                      NotificationsModel(
                                        family_id: widget.familyUserId,
                                        kid_id: widget.kidId,
                                        notification_title: title,
                                        notification_message: desc,
                                        type: 'withdrawal', 
                                        notification_id: '', 
                                        notification_amount: 0, 
                                        created_at: DateTime.now(), 
                                      );
                                  FirestoreService myFirestoreservice =
                                      FirestoreService();
                                  myFirestoreservice
                                      .addNotificationToNotificationCollections(
                                        withdrawalKidNotification,
                                      );

                                  setState(() {
                                    balance -= withdrawAmount;
                                  });

                                  Navigator.pop(context);
                                  showCustomSnackBar(
                                    "Withdrawal of \$${withdrawAmount.toStringAsFixed(2)} submitted!",
                                    isError: false,
                                  );
                                } catch (e) {
                                  showCustomSnackBar(
                                    "Failed to process withdrawal: $e",
                                    isError: true,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF60C56F),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
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
                                "Submit",
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

  @override
  Widget build(BuildContext context) {
    var navigator = Navigator.of(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          Navigator.pushReplacementNamed(
            context,
            '/kids-login-page',
            arguments: {'family-user-id': widget.familyUserId},
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
                            Text(
                              "\$${balance.toStringAsFixed(2)}",
                              style: GoogleFonts.fredoka(
                                fontSize: 50,
                                fontWeight: FontWeight.w700,
                              ),
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
                                      .currentPageIndex =
                                  1;
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
                          ElevatedButton(
                            onPressed: balance <= 0 ? null : _showWithdrawModal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: balance <= 0
                                  ? Colors.grey
                                  : const Color(0xFFFD6327),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 65,
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
                              "Withdraw",
                              style: GoogleFonts.fredoka(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
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
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Error loading chores: ${snapshot.error}',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 20,
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: () => setState(() {}),
                                      child: Text(
                                        'Retry',
                                        style: GoogleFonts.fredoka(
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ],
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
                            final pendingChores = chores
                                .where((c) => c['status'] == 'pending')
                                .toList();

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
                                  onTap: () => markChoreAsCompleted(
                                    chore['id'],
                                    chore['title'],
                                  ),
                                  child: SizedBox(
                                    height: 90,
                                    child: Card(
                                      color: const Color(0xFFEFE6E8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: const BorderSide(
                                          color: Colors.black,
                                          width: 2,
                                        ),
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.task_alt,
                                          color: Colors.green,
                                          size: 30,
                                        ),
                                        title: Text(
                                          chore['title'],
                                          style: GoogleFonts.fredoka(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          chore['description'],
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFAEDDFF),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: Colors.black,
                                              width: 2,
                                            ),
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
}
