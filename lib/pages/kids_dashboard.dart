// imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/pages/kids_chores_page.dart';
import 'package:wfinals_kidsbank/pages/kids_drawer.dart';

class KidsDashboard extends StatefulWidget {
  final String kidId;

  const KidsDashboard({super.key, required this.kidId});

  @override
  State<KidsDashboard> createState() => _KidsDashboardState();
}

class _KidsDashboardState extends State<KidsDashboard> {
  String kidName = '';
  double balance = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchKidInfo();
  }

  Future<void> fetchKidInfo() async {
    try {
      final kidSnapshot = await FirebaseFirestore.instance
          .collection('kids')
          .doc(widget.kidId)
          .get();

      if (kidSnapshot.exists) {
        final kidData = kidSnapshot.data()!;
        setState(() {
          kidName = kidData['firstName'];
        });
      }

      final paymentSnapshot = await FirebaseFirestore.instance
          .collection('kids_payment_info')
          .doc(widget.kidId)
          .get();

      setState(() {
        balance = paymentSnapshot['usable_balance']?.toDouble() ?? 0.0;
      });
    } catch (e) {
      debugPrint('Error fetching kid info: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Stream<List<Map<String, dynamic>>> getChoresStream() {
    return FirebaseFirestore.instance
        .collection('chores')
        .where('kid_id', isEqualTo: widget.kidId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return {
                'id': doc.id,
                'title': doc['chore_title'],
                'description': doc['chore_desc'],
                'price': doc['reward_money'],
                'status': doc['status'],
              };
            }).toList());
  }

  Future<void> markChoreAsCompleted(String choreId, String title) async {
    await FirebaseFirestore.instance
        .collection('chores')
        .doc(choreId)
        .update({'status': 'completed'});

    await FirebaseFirestore.instance.collection('notifications').add({
      'type': 'chore_completed',
      'kid_id': widget.kidId,
      'kid_name': kidName,
      'chore_title': title,
      'timestamp': FieldValue.serverTimestamp(),
    });

    showCustomSnackBar("✅ \"$title\" marked as completed!", isError: false);
  }

  void showCustomSnackBar(String message, {bool isError = false}) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
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
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: "What are you withdrawing (for)?",
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: descriptionController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: "For what?",
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {
                                if (withdrawAmount > 1) {
                                  setModalState(() => withdrawAmount -= 1);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFCA26),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.black, width: 2),
                                ),
                                child: const Icon(Icons.remove, size: 20),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                "\$${withdrawAmount.toStringAsFixed(2)}",
                                style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 5),
                            InkWell(
                              onTap: () => setModalState(() => withdrawAmount += 1),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFCA26),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.black, width: 2),
                                ),
                                child: const Icon(Icons.add, size: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            final title = titleController.text.trim();
                            final desc = descriptionController.text.trim();

                            if (title.isEmpty || desc.isEmpty || withdrawAmount <= 0) {
                              showCustomSnackBar("Please fill all fields and enter a valid amount.", isError: true);
                              return;
                            }

                            if (withdrawAmount > balance) {
                              showCustomSnackBar("Cannot withdraw more than your balance.", isError: true);
                              return;
                            }

                            Navigator.pop(context);

                            await FirebaseFirestore.instance
                                .collection('kids_payment_info')
                                .doc(widget.kidId)
                                .update({
                              'usable_balance': FieldValue.increment(-withdrawAmount),
                            });

                            await FirebaseFirestore.instance.collection('notifications').add({
                              'type': 'withdrawal',
                              'kid_id': widget.kidId,
                              'kid_name': kidName,
                              'title': title,
                              'description': desc,
                              'amount': withdrawAmount,
                              'timestamp': FieldValue.serverTimestamp(),
                            });

                            setState(() {
                              balance -= withdrawAmount;
                            });

                            showCustomSnackBar("Withdrawal of \$${withdrawAmount.toStringAsFixed(2)} submitted!", isError: false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF60C56F),
                            padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: const BorderSide(color: Colors.black, width: 2),
                            ),
                          ),
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {},
      child: Scaffold(
        drawer: KidsDrawer(selectedPage: 'dashboard', kidId: widget.kidId),
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFFFCA26),
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
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
                                "Hello, $kidName",
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
                                onTap: () {
                                  Scaffold.of(context).openDrawer();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black, width: 2),
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

                      // Balance Card
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
                            Image.asset('assets/piggy_bank.png', height: 200),
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

                      // Buttons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => KidsChoresPage(kidId: widget.kidId),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF927BD9),
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: const BorderSide(color: Colors.black, width: 2),
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
                              backgroundColor:
                                  balance <= 0 ? Colors.grey : const Color(0xFFFD6327),
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
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Chores List
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
                                  "No chores assigned yet!",
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
                                  onTap: () => markChoreAsCompleted(chore['id'], chore['title']),
                                  child: SizedBox(
                                    height: 90,
                                    child: Card(
                                      color: const Color(0xFFEFE6E8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: const BorderSide(color: Colors.black, width: 2),
                                      ),
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      child: ListTile(
                                        leading: const Icon(Icons.task_alt, color: Colors.green, size: 30),
                                        title: Text(
                                          chore['title'],
                                          style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          chore['description'],
                                          style: GoogleFonts.inter(fontSize: 12),
                                        ),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFAEDDFF),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.black, width: 2),
                                          ),
                                          child: Text(
                                            "\$${chore['price']}",
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
