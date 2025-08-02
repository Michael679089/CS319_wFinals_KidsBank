import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/chores_model.dart';
import 'package:wfinals_kidsbank/database/models/kid_model.dart';
import 'package:wfinals_kidsbank/database/models/kid_payment_info_model.dart';
import 'package:wfinals_kidsbank/database/models/notifications_model.dart';
import 'package:wfinals_kidsbank/pages/p_dashboard_drawer.dart';
import 'package:flutter/services.dart';
import 'package:wfinals_kidsbank/utilities/utilities.dart';

class ParentDashboard extends StatefulWidget {
  final String user_id;
  final String parent_id;

  const ParentDashboard({
    super.key,
    required this.user_id,
    required this.parent_id,
  });

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

double totalDepositedFunds = 0.0;

class _ParentDashboardState extends State<ParentDashboard> {
  // The Kids_Data Example: [{"kid_id": "abc123", "first_name": "Joshua", "balance": 25.50}];
  List<Map<String, dynamic>> Kids_Data = [];
  int totalChildren = 0;
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
    // In this function it looks like we need to get the name, the avatar path, and the available balance the user has.
    debugPrint("parentDashboard - loading kids data");
    var user_id = widget.user_id;
    var family_id = await FirestoreService.fetch_family_id(user_id) as String;

    // Step 1: Get list of kid models
    List<KidModel> KidsList =
        await FirestoreService.fetch_all_kids_by_family_id(family_id);
    debugPrint("PDashboardPage - KidsList: ${KidsList.toList().toString()}");
    List<Map<String, dynamic>> tempKidsData = [];
    double runningTotal = 0.0;

    // Step 2: Get the balance in each kid. - Example: [{"kid_id": "abc123", "first_name": "Joshua", "balance": 25.50}];
    for (var kid in KidsList) {
      // Step 1: Listing the things I need to fill
      var new_kid_name = kid.first_name;
      final new_kid_id = kid.id;

      // Step 2: Get the total_amount_left of kid
      double total_amount_left = 0.0;
      var kid_payment_info = await FirestoreService.readKidPaymentInfo(
        family_id,
      );
      total_amount_left = kid_payment_info!.total_amount_left;
      debugPrint(
        "parentDashboardPage - $new_kid_name - ${kid_payment_info.total_amount_left}",
      );

      // Step 3: Get the total_withdraw of kid
      double total_withdrawn = 0.0;
      final withdrawalsSnapshot =
          await FirestoreService.fetch_all_transactions_by_family_id_and_type(
            family_id,
            "withdrawal",
          );
      for (var withdrawalDoc in withdrawalsSnapshot) {
        total_withdrawn += (withdrawalDoc.amount);
      }

      debugPrint("checking");

      tempKidsData.add({
        "kid_id": new_kid_id,
        "first_name": new_kid_name,
        "avatar": kid.avatar_file_path,
        "total_amount_left": kid_payment_info.total_amount_left,
        "total_withdrawn": total_withdrawn,
      });
    }

    setState(() {
      Kids_Data = tempKidsData;
      totalChildren = tempKidsData.length;
      totalDepositedFunds = runningTotal;
    });

    debugPrint("PDashboardPage: KID's DATA: ${Kids_Data.toList().toString()}");
  }

  void _handleAddChoreSubmission(
    String kidId,
    TextEditingController titleController,
    TextEditingController descriptionController,
    double rewardMoney,
    messenger,
  ) async {
    debugPrint("hi");
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

                              style: Utilities.ourButtonStyle1(),
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
    debugPrint("hello");
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
                      // The Title
                      Text(
                        "Kid's Info",
                        style: GoogleFonts.fredoka(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // The Kid's List
                      Expanded(
                        child: ListView.builder(
                          itemCount: Kids_Data.length,
                          itemBuilder: (context, index) {
                            debugPrint("PDashboardPage - loading kid $index");
                            final kid = Kids_Data[index];
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
                                          kid['first_name'],
                                          style: GoogleFonts.fredoka(
                                            fontSize: 23,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "\$${kid['total_amount_left'].toStringAsFixed(2)}",
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
                                          } else {
                                            showManageFundsModal(
                                              context,
                                              kidName,
                                              kidId,
                                              kidAvatar,
                                            );
                                          }
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
