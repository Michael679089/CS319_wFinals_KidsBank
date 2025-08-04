import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wfinals_kidsbank/database/api/auth_service.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/kid_model.dart';
import 'package:wfinals_kidsbank/database/models/parent_model.dart';
import 'package:wfinals_kidsbank/utilities/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountSelectorPage extends StatefulWidget {
  final String user_id;
  final bool there_are_parents_in_family;

  const AccountSelectorPage({
    super.key,
    required this.user_id,
    required this.there_are_parents_in_family,
  });

  @override
  State<AccountSelectorPage> createState() => _AccountSelectorPageState();
}

class _AccountSelectorPageState extends State<AccountSelectorPage> {
  ParentModel? Parent;
  List<KidModel> Kids_List = [];
  bool isLoading = true;
  String? errorMessage;

  // Account Selection
  String? selectedId;
  String? selectedName;
  String? selectedRole;
  String? selectedAvatar;

  // Saved Credentials
  String familyName = "";
  String user_id = "";

  // Services
  final myFirestoreService = FirestoreService();

  // FUNCTIONS

  Future<void> updateFamilyName() async {
    user_id = widget.user_id;
    debugPrint("accountSelectorPage - fetching family name $user_id");
    var newFamilyName = await FirestoreService.fetch_family_name(user_id);

    if (newFamilyName.isEmpty) {
      debugPrint("accountSelectorPage - ERROR: Connection");
    }

    setState(() {
      familyName = newFamilyName;
    });
  }

  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
    });

    var navigator = Navigator.of(context);
    var family_object = await FirestoreService.readFamily(user_id);
    var family_id = family_object?.id as String;

    debugPrint("AccountSelectorPage@fetchUsers - familyID: $family_id");

    final user = AuthService.getCurrentUser();
    if (user == null) {
      setState(() {
        errorMessage = 'User not authenticated';
        isLoading = false;
      });
      return;
    } else {
      try {
        var the_main_parent = await FirestoreService.readParent(family_id);
        //Fetch kids from Firestore using family_id and include doc.id
        var kidsSnapshot = await FirebaseFirestore.instance
            .collection('kids')
            .where('family_id', isEqualTo: family_id)
            .get();

        Kids_List = kidsSnapshot.docs.map((doc) {
          var data = doc.data();
          return KidModel(
            id: doc.id,
            first_name: data['first_name'],
            last_name: data['last_name'],
            avatar_file_path: data['avatar_file_path'],
            pincode: data['pincode'],
            date_of_birth: (data['date_of_birth'] as Timestamp).toDate(),
            family_id: data['family_id'],
          );
        }).toList();
        var is_there_a_parent = (the_main_parent != null);

        if (is_there_a_parent == false) {
          debugPrint(
            "accountSelectorPage - the main parent is not found - will redirect to /parent-setup-page in 5 seconds",
          );
          debugPrint(
            "accountSelectorPage - user needs to add a single parent for the app to work.",
          );

          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              navigator.pushNamed(
                "/parent-setup-page",
                arguments: {"first-time-user": true},
              );
              debugPrint(
                "accountSelectorPage - redirected to /parent-setup-page",
              );
            }
          });
          return;
        }

        if (Kids_List.isEmpty) {
          debugPrint("AccountSelectorPage - Kids_List is empty");
        }

        setState(() {
          Parent = the_main_parent;
          isLoading = false;
        });

        debugPrint("accountSelectorPage - fetchUsers successfully");
        return;
      } catch (e) {
        debugPrint("accountSelectorPage - ERROR: fetching users $e");
        return;
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _handleSelectingAccount(
    String id,
    String name,
    String role,
    String avatar,
  ) {
    debugPrint("AccSelectPage - Handle Account Selection START");
    setState(() {
      selectedId = id;
      selectedName = name;
      selectedRole = role;
      selectedAvatar = avatar;
    });
    debugPrint("Selected $role: $name ($id)");
  }

  void _handleLoginButton() {
    debugPrint("AccSelectPage - Login Button START");

    var navigator = Navigator.of(context);

    debugPrint(
      "accountSelectorPage - LoginBTN pressed: $selectedRole - $selectedName",
    );

    if (selectedName == null || selectedRole == null) {
      UtilityTopSnackBar.show(
        context: context,
        message: "Please select a user above first",
      );
      return;
    }

    if (selectedRole == 'Parent') {
      debugPrint("AccSelectPage - selected user is a parent");
      String? my_parent_id = selectedId as String;
      if (my_parent_id.isNotEmpty) {
        navigator.pushNamed(
          "/parent-login-page",
          arguments: {"user-id": user_id, "parent-id": my_parent_id},
        );
      }
    } else if (selectedRole == 'Kid') {
      debugPrint("AccSelectPage - selected user is a kid");

      String my_kid_id = selectedId ?? '';

      if (my_kid_id.isNotEmpty) {
        navigator.pushNamed(
          "/kids-login-page",
          arguments: {"user-id": user_id, "kid-id": my_kid_id},
        );
      }
    }
    debugPrint("AccSelectPage - Login Button END");
  }

  void _handleLogOutFromFamily() async {
    var navigator = Navigator.of(context);

    var logoutResponse = await AuthService.logoutAccount();

    if (logoutResponse["status"] == "success") {
      debugPrint("log out successful");

      final prefs = await SharedPreferences.getInstance();
      prefs.remove('savedEmail');
      prefs.remove('savedPassword');
      prefs.remove('keepLoggedIn');

      (context, "Logged out successfully!", isError: false);
      navigator.pushReplacementNamed("/login-page");
      return;
    }

    debugPrint("log out failed");
  }

  @override
  void initState() {
    super.initState();
    updateFamilyName();
    fetchUsers();
  }

  Text _buildText(
    String text,
    double size, {
    bool isTextAlignmentCenter = false,
    Color textColor = Colors.black,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return Text(
      text,
      textAlign: isTextAlignmentCenter ? TextAlign.center : null,
      style: TextStyle(
        fontSize: size,
        fontWeight: fontWeight,
        fontFamily: GoogleFonts.fredoka().fontFamily,
        color: textColor,
      ),
    );
  }

  Text get title => _buildText("Hi!", 56);
  Text get subTitle => _buildText("Who is using?", 28.8);
  Text get parentsLabelText => _buildText("Parents", 20);
  Text get kidsLabelText => _buildText("[Kids]", 20);

  @override
  Widget build(BuildContext context) {
    Image myOwlImage = Image.asset(
      'assets/owl.png',
      height: 150,
      width: 240,
      alignment: Alignment.centerRight,
    );

    Row Top_Title_Display = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, subTitle],
          ),
        ),
        Flexible(flex: 1, child: myOwlImage),
      ],
    );

    Widget InnerDisplayContainer(bool isLoading) {
      final isFirstTimeUser = widget.there_are_parents_in_family == false;
      final selectedNameText = selectedName != null
          ? "Log in as $selectedName"
          : "Log in as";

      if (isLoading) {
        debugPrint("Showing loading indicator");
        return const Center(child: CircularProgressIndicator());
      }

      if (isFirstTimeUser) {
        debugPrint("Redirecting first-time user");
        return Padding(
          padding: const EdgeInsets.all(20),
          child: _buildText(
            "First-time user - redirecting to parent setup...",
            30,
            isTextAlignmentCenter: true,
          ),
        );
      }

      return Column(
        children: [
          // Parent Container
          if (Parent != null)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.black, width: 1.0),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(40, 20, 40, 20),
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _handleSelectingAccount(
                  Parent!.id as String,
                  Parent!.first_name,
                  "Parent",
                  Parent!.avatar_file_path,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      Parent!.avatar_file_path,
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildText(Parent!.first_name, 20),
                        _buildText("[Main Parent]", 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Kids Container
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                kidsLabelText,
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: Scrollbar(
                    thumbVisibility: true,
                    radius: const Radius.circular(10),
                    child: GridView.builder(
                      itemCount: Kids_List.length,
                      scrollDirection: Axis.vertical,
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemBuilder: (context, index) {
                        final kid = Kids_List[index];
                        final isSelected = selectedId == kid.id;
                        return GestureDetector(
                          onTap: () => _handleSelectingAccount(
                            kid.id as String,
                            kid.first_name,
                            "Kid",
                            kid.avatar_file_path,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(40),
                                  border: isSelected
                                      ? Border.all(color: Colors.blue, width: 3)
                                      : null,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: Image.asset(
                                    kid.avatar_file_path,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                kid.first_name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Login Button
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleLoginButton,
              style: Utilities.ourButtonStyle2(),
              child: _buildText(selectedNameText, 25),
            ),
          ),
        ],
      );
    }

    Widget MainDisplay(bool isLoading) {
      return Container(
        margin: EdgeInsets.all(20),
        child: Column(
          children: [
            Top_Title_Display,
            Builder(
              builder: (context) {
                final parentBorderRadius = BorderRadius.circular(20);
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: parentBorderRadius,
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: parentBorderRadius,
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxWidth: 700),
                      child: InnerDisplayContainer(isLoading),
                    ),
                  ),
                );
              },
            ),

            // Log out Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: ElevatedButton(
                onPressed: _handleLogOutFromFamily,
                style: Utilities.ourButtonStyle3(),
                child: Text(
                  "Log out from Family",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

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
          title: const Text(" "),
          automaticallyImplyLeading: false,
        ),
        body: MainDisplay(isLoading),
      ),
    );
  }
}
