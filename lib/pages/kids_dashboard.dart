import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // Uncomment for Firebase
import 'kids_chores_page.dart';

class KidsDashboard extends StatefulWidget {
  const KidsDashboard({super.key});

  @override
  State<KidsDashboard> createState() => _KidsDashboardState();
}

class _KidsDashboardState extends State<KidsDashboard> {
  String kidName = "Jane"; // later fetch from Firebase
  double balance = 25.75; // later fetch from Firebase

  final List<Map<String, dynamic>> chores = [
    {'title': 'Clean Room', 'description': 'Tomorrow', 'price': 3},
    {'title': 'Lababo Duty', 'description': 'Tomorrow', 'price': 8},
  ];

  void _showWithdrawModal(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    double withdrawAmount = 1.0;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              reverse: true,
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
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: "What are you withdrawing (for)?",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: descriptionController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: "For what?",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Amount",
                            style: GoogleFonts.fredoka(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {
                                if (withdrawAmount > 1) {
                                  setModalState(() {
                                    withdrawAmount -= 1;
                                  });
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
                                color: Colors.white,
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
                            const SizedBox(width: 5),
                            InkWell(
                              onTap: () {
                                setModalState(() {
                                  withdrawAmount += 1;
                                });
                              },
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
                          onPressed: () {
                            final String title = titleController.text.trim();
                            final String description = descriptionController.text.trim();

                            if (title.isEmpty || description.isEmpty || withdrawAmount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please fill in all fields and set a valid amount."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (withdrawAmount > balance) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Cannot withdraw more than your balance."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            setState(() {
                              balance -= withdrawAmount;
                            });

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Withdrawal of \$${withdrawAmount.toStringAsFixed(2)} submitted!",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );

                            // Uncomment for Firestore saving
                            /*
                            FirebaseFirestore.instance.collection('withdraw_requests').add({
                              'kidName': kidName,
                              'title': title,
                              'description': description,
                              'amount': withdrawAmount,
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                            */
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

  void _showEmptyBalanceAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Balance Empty",
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Your balance is empty! You cannot withdraw.",
          style: GoogleFonts.fredoka(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: GoogleFonts.fredoka(
                color: const Color(0xFF927BD9),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFFCA26),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Hello, $kidName",
                  style: GoogleFonts.fredoka(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
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
                    Image.asset(
                      "assets/piggy_bank.png",
                      height: 200,
                    ),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KidsChoresPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF927BD9),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 25),
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
                    onPressed: balance <= 0
                        ? () => _showEmptyBalanceAlert(context)
                        : () => _showWithdrawModal(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFD6327),
                      padding: const EdgeInsets.symmetric(horizontal: 65, vertical: 25),
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
              Text(
                "Chores",
                style: GoogleFonts.fredoka(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: chores.isNotEmpty
                    ? ListView.builder(
                        itemCount: chores.length,
                        itemBuilder: (context, index) {
                          final chore = chores[index];
                          return SizedBox(
                            height: 95,
                            child: Card(
                              color: const Color(0xFFEFE6E8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: Colors.black, width: 2),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: const Icon(Icons.check_circle, color: Colors.green),
                                title: Text(
                                  chore['title'],
                                  style: GoogleFonts.fredoka(
                                    fontSize: 23,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  chore['description'],
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFAEDDFF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.black, width: 2),
                                  ),
                                  child: Text(
                                    "\$${chore['price']}",
                                    style: GoogleFonts.fredoka(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          "No chores assigned yet!",
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
