import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wfinals_kidsbank/database/api/auth_service.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/kid_model.dart';
import 'package:wfinals_kidsbank/database/models/parent_model.dart';
import 'package:wfinals_kidsbank/utilities/utilities.dart';

class AccountSelectorPage extends StatefulWidget {
  final String user_id;
  final bool there_are_parents_in_family;

  const AccountSelectorPage({super.key, required this.user_id, required this.there_are_parents_in_family});

  @override
  State<AccountSelectorPage> createState() => _AccountSelectorPageState();
}

class _AccountSelectorPageState extends State<AccountSelectorPage> {
  ParentModel? Parent;
  List<KidModel> Kids_List = [];
  bool isLoading = true;
  String? errorMessage;

  // This is Account Selector, these are for selecting the account to log in as:
  String? selectedId;
  String? selectedName;
  String? selectedRole;
  String? selectedAvatar;

  // Saved Credentials
  String familyName = "";
  String user_id = "";

  // My Services
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

    // Step 1: Get the USER_ID
    final user = AuthService.getCurrentUser();
    if (user == null) {
      setState(() {
        errorMessage = 'User not authenticated';
        isLoading = false;
      });
      return;
    } else {
      // Step 2: Fetch the single parent and all the kids.
      try {
        var the_main_parent = await FirestoreService.readParent(family_id);
        var newKids = await FirestoreService.fetch_all_kids_by_family_id(family_id);
        var is_there_a_parent = (the_main_parent != null);

        if (is_there_a_parent == false) {
          debugPrint("accountSelectorPage - the main parent is not found - will redirect to /parent-setup-page in 5 seconds");
          debugPrint("accountSelectorPage - user needs to add a single parent for the app to work.");

          // Step 3: Add 5-second delay for users to read before navigation
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              navigator.pushNamed("/parent-setup-page", arguments: {"first-time-user": true});
              debugPrint("accountSelectorPage - redirected to /parent-setup-page");
            }
          });
          return;
        }

        if (newKids.isEmpty) {
          debugPrint("AccountSelectorPage - newKids list is empty");
        }

        setState(() {
          Parent = the_main_parent;
          Kids_List = newKids;
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

  void _handleSelectingAccount(String id, String name, String role, String avatar) {
    debugPrint("AccSelectPage - Handle Account Selection START");
    if (role == "Parent") {
      debugPrint("Selected parent ID: $id");

      setState(() {
        selectedAvatar = avatar;
        selectedName = name;
        selectedId = id;
        selectedRole = role;
      });
    } else if (role == "Kid") {
      debugPrint("Selected Kid ID: $id");
    }

    debugPrint("AccSelectPage - Handle Account Selection END");
  }

  void _handleLoginButton() {
    debugPrint("AccSelectPage - Login Button START");

    var navigator = Navigator.of(context);

    debugPrint("accountSelectorPage - LoginBTN pressed: $selectedRole - $selectedName");

    if (selectedName == null || selectedRole == null) {
      UtilityTopSnackBar.show(context: context, message: "Please select a user above first");
      return;
    }

    if (selectedRole == 'Parent') {
      debugPrint("AccSelectPage - selected user is a parent");

      String? my_parent_id = selectedId as String;
      if (my_parent_id.isNotEmpty) {
        navigator.pushNamed("/parent-login-page", arguments: {"user-id": user_id, "parent-id": my_parent_id});
      }
    } else if (selectedRole == 'Kid') {
      debugPrint("AccSelectPage - selected user is a kid");
    }
    debugPrint("AccSelectPage - Login Button END");
  }

  // Helper method to show SnackBar, consistent with LoginPage
  void _handleLogOutFromFamily() async {
    var navigator = Navigator.of(context);

    // Step 1: Log User out but don't redirect him yet.
    var logoutResponse = await AuthService.logoutAccount();

    if (logoutResponse["status"] == "success") {
      debugPrint("log out successful");

      // Step 2: If log out successful removed shared preferences
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('savedEmail');
      prefs.remove('savedPassword');
      prefs.remove('keepLoggedIn');

      // Step 3: Finally Redirect him
      (context, "Logged out successfully!", isError: false);
      navigator.pushReplacementNamed("/login-page");
      return;
    }

    debugPrint("log out failed");
  }

  // INITSTATE
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
    Color textColor = Colors.black, // Changed from Colors to Color
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return Text(
      text,
      textAlign: isTextAlignmentCenter ? TextAlign.center : null,
      style: TextStyle(
        fontSize: size,
        fontWeight: fontWeight,
        fontFamily: GoogleFonts.fredoka().fontFamily,
        color: textColor, // Added color parameter
      ),
    );
  }

  Text get title => _buildText("Hi!", 56);
  Text get subTitle => _buildText("Who is using?", 28.8);
  Text get parentsLabelText => _buildText("Parents", 20);
  Text get kidsLabelText => _buildText("[Kids]", 20);

  // BUILD FUNCTION

  @override
  Widget build(BuildContext context) {
    Image myOwlImage = Image.asset('assets/owl.png', height: 150, width: 240, alignment: Alignment.centerRight);

    Row Top_Title_Display = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          flex: 2,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, subTitle]),
        ),
        Flexible(flex: 1, child: myOwlImage),
      ],
    );

    Widget InnerDisplayContainer(bool isLoading) {
      var is_users_first_time_signing_in = (widget.there_are_parents_in_family == false);

      String? selected_name = selectedName ?? "";
      var full_string_selected_name = "Log in as $selected_name";

      if (isLoading == false && is_users_first_time_signing_in == false) {
        debugPrint("AccountSelectorPage - showing account selector inner display");
        return Column(
          children: [
            // Main Parent Container
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(40, 20, 40, 20),
              child: Column(
                children: [
                  Center(
                    // The Thing that's makes this clickable
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, // Remove default padding
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Tight press area
                        foregroundColor: Colors.black, // Default text color
                      ),
                      onPressed: () {
                        _handleSelectingAccount(Parent!.id as String, Parent!.first_name, "Parent", Parent!.avatar_file_path);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(Parent!.avatar_file_path, width: 100, height: 100),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [_buildText(Parent!.first_name, 20), _buildText("[Main Parent]", 20)],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // KIDS Container
            Container(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
              child: Column(
                children: [
                  // The Title Kids Label
                  kidsLabelText,
                  const SizedBox(height: 10),

                  // Gridview
                  GridView.count(
                    shrinkWrap: true, // Important for nested scrolling
                    physics: const NeverScrollableScrollPhysics(), // Disable nested scrolling
                    crossAxisCount: 3, // 2 items per row
                    childAspectRatio: 3, // Width/height ratio for each item
                    mainAxisSpacing: 10, // Vertical spacing
                    crossAxisSpacing: 10, // Horizontal spacing
                    children: Kids_List.map(
                      (kid) => Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        height: 160,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Image.asset(kid.avatar_file_path, alignment: Alignment.centerRight),
                            Text(kid.first_name),
                          ],
                        ),
                      ),
                    ).toList(),
                  ),
                ],
              ),
            ),

            // The LOGIN Button.
            Container(
              color: Colors.black,
              width: double.infinity,
              padding: EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _handleLoginButton,
                style: Utilities().ourButtonStyle2(),
                child: _buildText(full_string_selected_name, 25, textColor: Colors.black),
              ),
            ),
          ],
        );
      } else if (is_users_first_time_signing_in) {
        debugPrint("AccountSelectorPage - inner display is stopped because user is first time user");
        return Column(
          children: [
            Padding(
              padding: EdgeInsetsGeometry.all(20),
              child: _buildText("Its users first time using the app... redirecting to parent setup...", 30, isTextAlignmentCenter: true),
            ),
          ],
        );
      } else {
        debugPrint("AccountSelectorPage - showing inner display ciruclar progress");
        return Center(child: CircularProgressIndicator());
      }
    }

    Widget MainDisplay(bool isLoading) {
      return Container(
        margin: EdgeInsets.all(20),
        child: Column(
          children: [
            Top_Title_Display,
            // ACCOUNT SELECTOR PAGE - Container with ClipRect;
            Builder(
              builder: (context) {
                final parentBorderRadius = BorderRadius.circular(20);
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: parentBorderRadius,
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: parentBorderRadius, // Same as parent
                    child: Container(width: double.infinity, constraints: BoxConstraints(maxWidth: 700), child: InnerDisplayContainer(isLoading)),
                  ),
                );
              },
            ),

            // -----------------------------------------------

            // Log out Button
            ElevatedButton(
              onPressed: _handleLogOutFromFamily,
              style: Utilities().ourButtonStyle1(),
              child: Text("Log out from Family", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    ///
    ///
    ///
    ///
    ///

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        debugPrint("accountSelectorPage - User attempted to go back through phone btns");
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFCA26),
        appBar: AppBar(backgroundColor: const Color(0xFFFFCA26), title: const Text("Account Selector Page"), automaticallyImplyLeading: false),
        body: MainDisplay(isLoading),
      ),
    );
  }
}
