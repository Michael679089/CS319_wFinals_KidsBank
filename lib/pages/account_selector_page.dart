import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/database/api/auth_service.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/kid_model.dart';
import 'package:wfinals_kidsbank/database/models/parent_model.dart';

class AccountSelectorPage extends StatefulWidget {
  const AccountSelectorPage({super.key});

  @override
  State<AccountSelectorPage> createState() => _AccountSelectorPageState();
}

class _AccountSelectorPageState extends State<AccountSelectorPage> {
  // Saved Credentials
  String familyName = "";
  String familyUserId = "";
  List<ParentModel> parents = [];
  List<KidModel> kids = [];
  bool isLoading = true;
  String? errorMessage;
  String? selectedParentId;
  String? selectedKidId;
  String? selectedName;
  String? selectedRole;
  String? selectedAvatar;
  OverlayEntry? overlayEntry;

  // My Services
  final myFirestoreAPI = FirestoreAPI();
  final myAuthService = AuthService();

  // FUNCTIONS

  Future<void> updateFamilyName() async {
    final myModalRoute = ModalRoute.of(context);

    if (myModalRoute == null) {
      setState(() {
        errorMessage = 'Navigation arguments not found';
        isLoading = false;
      });
      return;
    }

    final args = myModalRoute.settings.arguments as Map<String, String>;
    final newFamilyName = args["family-name"] as String;
    final newUserId = args["family-user-id"] as String;

    setState(() {
      familyName = newFamilyName;
      familyUserId = newUserId;
    });

    debugPrint(
      "accountSelectorPage - Update family name success - $familyName + $familyUserId",
    );
  }

  Future<void> fetchUsers() async {
    var navigator = Navigator.of(context);

    try {
      final user = myAuthService.getCurrentUser();
      if (user == null) {
        setState(() {
          errorMessage = 'User not authenticated';
          isLoading = false;
        });
        return;
      }

      final parentList = await myFirestoreAPI.getParentsByFamilyUserId(
        familyUserId,
      );
      final kidList = await myFirestoreAPI.getKidsByFamilyUserId(familyUserId);

      setState(() {
        parents = parentList;
        kids = kidList;
        isLoading = false;
      });

      if (parentList.isEmpty) {
        navigator.pushNamed(
          '/parent-setup-page',
          arguments: {
            "family-name": familyName,
            "family-user-id": familyUserId,
          },
        );
        debugPrint(
          "accountSelectorPage - No Parent found, Redirected to Parent-Setup-Page",
        );
      } else {
        debugPrint(
          "accountSelectorPage - Successfully fetched parents and kids",
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load users: $e';
        isLoading = false;
      });
    }
  }

  void selectParent(ParentModel parent, String parentId) {
    setState(() {
      selectedParentId = parent.parentId;
      selectedKidId = null; // Deselecting Kid
      selectedName = "${parent.firstName} ${parent.lastName}";
      selectedRole = "parent";
      selectedAvatar = parent.avatar;
    });
    debugPrint("accountSelectorPage - Selected parent = $parent --- $parentId");
  }

  void selectKid(KidModel kid, String kidId) {
    setState(() {
      selectedParentId = null; // Deselecting Parent
      selectedKidId = kidId;
      selectedName = kid.firstName;
      selectedRole = "kid";
      selectedAvatar = kid.avatar;
    });
  }

  void login() {
    var navigator = Navigator.of(context);

    debugPrint(
      "accountSelectorPage - LoginBTN pressed: $selectedRole - $selectedName",
    );

    if (selectedName == null || selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please select a user above first",
            style: TextStyle(fontFamily: GoogleFonts.fredoka().fontFamily),
          ),
        ),
      );
      return;
    }

    if (selectedRole == 'parent') {
      navigator.pushNamed(
        '/parent-login-page',
        arguments: {
          'parentId': selectedParentId,
          'name': selectedName,
          'avatar': selectedAvatar,
          'family-name': familyName,
          'family-user-id': familyUserId,
        },
      );
      debugPrint(
        "accountSelectorPage - Redirecting to parent-login-page with data: ...",
      );
      debugPrint("--> $selectedName");
      debugPrint("--> $selectedParentId");
    } else {
      navigator.pushNamed(
        '/kids-login-page',
        arguments: {
          'kidDocId': selectedKidId,
          'kidName': selectedName,
          'avatarPath': selectedAvatar,
          'family-name': familyName,
          'family-user-id': familyUserId,
        },
      );
    }
  }

  void addParent() async {
    // For Adding New Parents Function - Opens up Parent Set Up Page.
    debugPrint("accountSelectorPage - Add Parent button tapped");

    var myOverlayOf = Overlay.of(context);
    var messenger = ScaffoldMessenger.of(context);
    var navigator = Navigator.of(context);

    try {
      final user = myAuthService.getCurrentUser();
      if (user == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              "User not authenticated",
              style: TextStyle(fontFamily: GoogleFonts.fredoka().fontFamily),
            ),
          ),
        );
        return;
      }

      final cardNumber = await myFirestoreAPI.getFamilyPaymentCardNumber(
        user.uid,
      );
      if (cardNumber == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              "No payment information found",
              style: TextStyle(fontFamily: GoogleFonts.fredoka().fontFamily),
            ),
          ),
        );
        return;
      }
      final lastFourDigits = cardNumber.length >= 4
          ? cardNumber.substring(cardNumber.length - 4)
          : cardNumber;

      final TextEditingController controller = TextEditingController();

      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: 100,
          left: 20,
          right: 20,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Enter the last 4 digits of your linked card",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: GoogleFonts.fredoka().fontFamily,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Last 4 digits",
                      labelStyle: TextStyle(
                        fontFamily: GoogleFonts.fredoka().fontFamily,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          overlayEntry?.remove();
                          overlayEntry = null;
                        },
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontFamily: GoogleFonts.fredoka().fontFamily,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final input = controller.text;
                          if (input == lastFourDigits) {
                            overlayEntry?.remove();
                            overlayEntry = null;
                            // Navigate and wait for result
                            final result = await navigator.pushNamed(
                              "/parent-setup-page",
                              arguments: {
                                "family-name": familyName,
                                "family-user-id": familyUserId,
                              },
                            );
                            // Assuming parent-setup-page returns the new ParentModel
                            if (result != null && result is ParentModel) {
                              setState(() {
                                parents = [...parents, result];
                              });
                              debugPrint(
                                "accountSelectorPage - New parent added: ${result.firstName}",
                              );
                            }
                            debugPrint(
                              "accountSelectorPage - OverlayEntry Input Success. Redirected to Parent-Setup-Page",
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Incorrect card number",
                                  style: TextStyle(
                                    fontFamily:
                                        GoogleFonts.fredoka().fontFamily,
                                  ),
                                ),
                              ),
                            );
                            debugPrint(
                              "accountSelectorPage - Failed Overlay input",
                            );
                          }
                        },
                        child: Text(
                          "Submit",
                          style: TextStyle(
                            fontFamily: GoogleFonts.fredoka().fontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      myOverlayOf.insert(overlayEntry!);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            "Error fetching payment info: $e",
            style: TextStyle(fontFamily: GoogleFonts.fredoka().fontFamily),
          ),
        ),
      );
      debugPrint("accountSelectorPage - ERROR: Happened $e");
    }
  }

  void mySequenceOne() async {
    await updateFamilyName();
    await fetchUsers();
    debugPrint(
      "accountSelectorPage - kids: ${kids.length} & parents: ${parents.length}",
    );
    debugPrint("accountSelectorPage - ...");
    debugPrint("... Parent:");
    for (var parent in parents) {
      var myParentId = parent.parentId;
      debugPrint(myParentId);
      debugPrint("${parent.toMap()}");
    }
    debugPrint("... Kid:");
    for (var kid in kids) {
      debugPrint("${kid.toMap()}");
    }
  }

  // INITSTATE
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mySequenceOne();
    });
  }

  Text get title => _buildText("Hi!", 56);
  Text get subTitle => _buildText("Who is using?", 28.8);
  Text get parentsLabelText => _buildText("Parents", 20);
  Text get kidsLabelText => _buildText("Kids", 20);

  Text _buildText(String text, double size) {
    return Text(
      text,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        fontFamily: GoogleFonts.fredoka().fontFamily,
      ),
    );
  }

  // BUILD FUNCTION

  @override
  Widget build(BuildContext context) {
    Column myColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [title, subTitle],
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        debugPrint(
          "accountSelectorPage - User attempted to go back through phone btns",
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFCA26),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFCA26),
          title: const Text("Account Selector Page"),
          automaticallyImplyLeading: false,
        ),
        body: Container(
          margin: EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(flex: 2, child: myColumn),
                    Flexible(
                      flex: 1,
                      child: Image.asset(
                        'assets/owl.png',
                        height: 150,
                        width: 240,
                        alignment: Alignment.centerRight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                      child: Column(
                        children: [parentsLabelText, _parentsDisplay()],
                      ),
                    ),
                    Divider(
                      color: Colors.black,
                      thickness: 2,
                      indent: 20,
                      endIndent: 20,
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                      child: Column(children: [kidsLabelText, _kidsDisplay()]),
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                      child: ElevatedButton(
                        onPressed: login,
                        child: Text(
                          "Log in as $selectedName",
                          style: TextStyle(
                            fontFamily: GoogleFonts.fredoka().fontFamily,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Positioned myOwl = Positioned(
    child: Container(
      color: Colors.red,
      child: Image.asset('assets/owl.png', height: 150, width: 240),
    ),
  );

  // Modified _parentsDisplay method
  Widget _parentsDisplay() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: TextStyle(
            fontFamily: GoogleFonts.fredoka().fontFamily,
            fontSize: 16,
            color: Colors.red,
          ),
        ),
      );
    }
    if (parents.isEmpty) {
      return const Center(
        child: Text(
          'No parents found',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...parents.asMap().entries.map((entry) {
              final parent = entry.value;
              final parentId = entry.key.toString();

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => selectParent(parent, parentId),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(
                                (0.3 * 255).toInt(),
                              ),
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: selectedParentId == parentId
                                ? Colors.blueAccent
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundImage: AssetImage(parent.avatar),
                          radius: 40,
                          child: parent.avatar.isEmpty
                              ? const Text("Hi")
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            "${parent.firstName} ${parent.lastName}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: GoogleFonts.fredoka().fontFamily,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Add Parent Button
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: addParent,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.3 * 255).toInt()),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[300],
                        child: const Icon(
                          Icons.add,
                          size: 40,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Add Parent",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: GoogleFonts.fredoka().fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modified _kidsDisplay method
  Widget _kidsDisplay() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: TextStyle(
            fontFamily: GoogleFonts.fredoka().fontFamily,
            fontSize: 16,
            color: Colors.red,
          ),
        ),
      );
    }
    if (kids.isEmpty) {
      return const Center(
        child: Text(
          'No kids found',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...kids.asMap().entries.map((entry) {
              final kid = entry.value;
              final kidId = entry.key.toString();

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => selectKid(kid, kidId),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(
                                (0.3 * 255).toInt(),
                              ),
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: selectedKidId == kidId
                                ? Colors.blueAccent
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundImage: AssetImage(kid.avatar),
                          radius: 40,
                          child: kid.avatar.isEmpty ? const Text("Hi") : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            kid.firstName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: GoogleFonts.fredoka().fontFamily,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
