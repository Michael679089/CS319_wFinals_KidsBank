import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/database/api/auth_service.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/kid_model.dart';
import 'package:wfinals_kidsbank/database/models/parent_model.dart';
import 'login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KidsSetupPage extends StatefulWidget {
  final bool cameFromParentDashboard;
  final String user_id;

  const KidsSetupPage({
    super.key,
    required this.cameFromParentDashboard,
    required this.user_id,
  });

  @override
  State<KidsSetupPage> createState() => _KidsSetupPageState();
}

class _KidsSetupPageState extends State<KidsSetupPage> {
  String parentName = '';
  String parentAvatar = '';
  String user_id = '';
  String parentId = '';

  // INITSTATE Function:

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadParentInfo();
    });
  }

  //
  // Other Functions:
  //

  void _showEditKidModal(KidModel kid) {
  final firstNameController = TextEditingController(text: kid.first_name);
  final lastNameController = TextEditingController(text: kid.last_name);
  final dobController = TextEditingController(
    text: "${kid.date_of_birth.year}-${kid.date_of_birth.month.toString().padLeft(2, '0')}-${kid.date_of_birth.day.toString().padLeft(2, '0')}"
  );
  final pincodeController = TextEditingController(text: kid.pincode);

  String selectedAvatar = kid.avatar_file_path;
  final avatars = [
    'assets/avatar1.png',
    'assets/avatar2.png',
    'assets/avatar3.png',
    'assets/avatar4.png',
    'assets/avatar5.png',
    'assets/avatar6.png',
  ];

  final formKey = GlobalKey<FormState>();

  void showAvatarPickerModal(Function(void Function()) setModalState) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 20,
              children: avatars.map((avatar) {
                return GestureDetector(
                  onTap: () {
                    setModalState(() {
                      selectedAvatar = avatar;
                    });
                    Navigator.of(context).pop();
                  },
                  child: CircleAvatar(
                    backgroundImage: AssetImage(avatar),
                    radius: 30,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Kid Account',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: GoogleFonts.fredoka().fontFamily,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Avatar
                      Center(
                        child: GestureDetector(
                          onTap: () => showAvatarPickerModal(setModalState),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundImage: AssetImage(selectedAvatar),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Tap avatar to change',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: GoogleFonts.fredoka().fontFamily,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // First Name
                      TextFormField(
                        controller: firstNameController,
                        decoration: _inputDecoration('First Name'),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Last Name
                      TextFormField(
                        controller: lastNameController,
                        decoration: _inputDecoration('Last Name'),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Date of Birth
                      TextFormField(
                        controller: dobController,
                        decoration: _inputDecoration('Date of Birth'),
                        readOnly: true,
                        onTap: () async {
                          FocusScope.of(context).unfocus();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: kid.date_of_birth,
                            firstDate: DateTime(2005),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            dobController.text =
                                "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                            setModalState(() {});
                          }
                        },
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Pincode
                      TextFormField(
                        controller: pincodeController,
                        decoration: _inputDecoration('Pincode'),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          } else if (value.length != 4) {
                            return 'Pincode must be 4 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            try {
                              await FirebaseFirestore.instance
                                  .collection('kids')
                                  .doc(kid.id)
                                  .update({
                                'first_name': firstNameController.text.trim(),
                                'last_name': lastNameController.text.trim(),
                                'date_of_birth': DateTime.parse(dobController.text),
                                'pincode': pincodeController.text.trim(),
                                'avatar_file_path': selectedAvatar,
                              });

                              Navigator.of(context).pop();
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Kid updated successfully.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4E88CF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: const BorderSide(color: Colors.black, width: 2),
                          ),
                          child: Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontFamily: GoogleFonts.fredoka().fontFamily,
                            ),
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
  );
}
InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      fontFamily: GoogleFonts.fredoka().fontFamily,
      fontWeight: FontWeight.w500,
      color: Colors.black87,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Colors.black, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Colors.black, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Colors.blue, width: 2),
    ),
  );
}
  // loading information functions:
  Future<void> _loadParentInfo() async {
    debugPrint("KSetupPage - loadParentInfo Function START");

    // Step 1: Let's get the Parent-ID:
    user_id = widget.user_id;
    var family_id = await FirestoreService.fetch_family_id(user_id) as String;
    var parent_object = await FirestoreService.readParent(family_id);

    if (user_id.isNotEmpty && parent_object != null) {
      final lastName = (parent_object.last_name).isNotEmpty
          ? '${parent_object.last_name[0].toUpperCase()}${parent_object.last_name.substring(1).toLowerCase()}'
          : '';

      final firstInitial = (parent_object.first_name).isNotEmpty
          ? '${parent_object.first_name[0].toUpperCase()}.'
          : '';

      final displayName =
          '$lastName${lastName.isNotEmpty && firstInitial.isNotEmpty ? ', ' : ''}$firstInitial';

      debugPrint('Formatted name: $displayName');

      setState(() {
        parentName = displayName;
        parentAvatar = parent_object.avatar_file_path;
        parentId = parent_object.id?.toString() ?? '';
      });
    }
  }

  Future<List<KidModel>> _loadKids() async {
    var user = AuthService.getCurrentUser();
    if (user != null) {
      var user_id = user.uid;
      var family_object = await FirestoreService.readFamily(user_id);
      var family_id = family_object?.id;

      var kidsList = FirestoreService.fetch_all_kids_by_family_id(family_id!);

      return kidsList;
    } else {
      return [];
    }
  }

  // -----

  void _handleContinueButton() async {
    debugPrint("KSetupPage - _handleContinueButton START");
    debugPrint("KSetupPage - continue button was pressed");

    // Step 1: transfer back the user to parent dashboard if user came from parent dashboard,
    // otherwise send user back to account selector page.
    debugPrint(
      "KSetupPage - did user came from dashboard? ${widget.cameFromParentDashboard}",
    );
    if (widget.cameFromParentDashboard == true) {
      Navigator.of(context).pushReplacementNamed(
        "/parent-dashboard-page",
        arguments: {"user-id": user_id, "parent-id": parentId},
      );
      debugPrint(
        "kidsSetupPage - user from dashboard. user pressed continue. Redirected to parent-dashboard-page",
      );
    } else {
      Navigator.of(context).pushReplacementNamed(
        "/account-selector-page",
        arguments: {"user-id": user_id, 'there-are-parent-in-family': true},
      );
      debugPrint(
        "kidsSetupPage - user not from dashboard. user pressed continue. Redirected to account-selector-page",
      );
    }
  }

  void _handleAddKidFunction() async {
    debugPrint("KSetupPage - _handleAddKidFunction START");
    debugPrint("KSetupPage - add kid button was pressed");
    var navigator = Navigator.of(context);
    var user = AuthService.getCurrentUser();

    if (user != null) {
      debugPrint(
        "KSetupPage - addKids BTN pressed, redirected to create-kids-account-page",
      );
      debugPrint("KSetupPage - what's the parent id: $parentId");
      navigator.pushNamed(
        '/create-kids-account-page',
        arguments: {
          "parent-id": parentId,
          "came-from-parent-dashboard": widget.cameFromParentDashboard,
          "user-id": user.uid,
        },
      );
    }
    debugPrint("KSetupPage - _handleAddKidFunction END");
  }

  //
  // BUILD FUNCTION
  //

  @override
  Widget build(BuildContext context) {
    var navigator = Navigator.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return;
        }

        if (widget.cameFromParentDashboard) {
          navigator.pushReplacementNamed(
            "/parent-dashboard-page",
            arguments: {
              "user-id": widget.user_id, "parent-id": parentId
              },
          );
          debugPrint(
            "kidsSetupPage - User that came from parent dashboard pressed back on phone - redirected to Parent-Dashbaord-Page",
          );
          return;
        }

        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Log Out'),
            content: const Text(
              'Do you want to log out and return to the login page?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () async {
                  await AuthService.logoutAccount();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  }
                },
                child: const Text('Yes'),
              ),
            ],
          ),
        );

        if (shouldLogout == true && context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFCA26),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Parent Info Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: parentAvatar.isNotEmpty
                          ? AssetImage(parentAvatar)
                          : const AssetImage('assets/avatar1.png'),
                      radius: 50,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parentName.isNotEmpty ? parentName : "Parent",
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            fontFamily: GoogleFonts.fredoka().fontFamily,
                          ),
                        ),
                        Text(
                          "[Parent]",
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w600,
                            fontFamily: GoogleFonts.fredoka().fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Set up kid’s account",
                  style: TextStyle(
                    fontSize: 28.8,
                    fontWeight: FontWeight.w700,
                    fontFamily: GoogleFonts.fredoka().fontFamily,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Kids List Container
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFefe6e8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: FutureBuilder<List<KidModel>>(
                      future: _loadKids(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final List<KidModel> kids =
                            snapshot.data as List<KidModel>;

                        return ListView(
                          children: [
                            ...kids.map((kid) => _buildKidTile(kid)),
                            const SizedBox(height: 12),

                            // The Add Kid Button + + +
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  _handleAddKidFunction();
                                },
                                child: CircleAvatar(
                                  backgroundColor: const Color(0xFF4E88CF),
                                  radius: 30,
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 32,
                                  ),
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

              const SizedBox(height: 20),

              // Continue Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _handleContinueButton();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4E88CF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.black, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        fontFamily: GoogleFonts.fredoka().fontFamily,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Color randomizeColors() {
    final Random random = Random();

    // Hue: full range 0–360
    final double hue = random.nextDouble() * 360;

    // Saturation: 0.4–0.7 for mild colors
    final double saturation = 0.4 + random.nextDouble() * 0.3;

    // Lightness: 0.75–0.9 for pale colors
    final double lightness = 0.75 + random.nextDouble() * 0.15;

    final hslColor = HSLColor.fromAHSL(1.0, hue, saturation, lightness);
    return hslColor.toColor();
  }

  // Function to confirm deletion of a kid
  Future<void> deleteKid(String kidId) async {
    try {
      await FirebaseFirestore.instance
          .collection('kids')
          .doc(kidId)
          .delete();
      debugPrint("Kid with ID $kidId deleted successfully");
    } catch (e) {
      debugPrint("Error deleting kid: $e");
      rethrow;
    }
  }
  void _confirmDeleteKid(KidModel kid) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Kid'),
      content: Text('Are you sure you want to delete ${kid.first_name}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

if (confirm == true) {
 await deleteKid(kid.id!);
  setState(() {}); // Refresh UI
}
}

  Widget _buildKidTile(KidModel kid) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: randomizeColors(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: AssetImage(kid.avatar_file_path),
            radius: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              kid.first_name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: GoogleFonts.fredoka().fontFamily,
                color: Colors.black,
              ),
            ),
          ),
          if (widget.cameFromParentDashboard) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () async {
                final doc = await FirebaseFirestore.instance
                    .collection('kids')
                    .doc(kid.id)
                    .get();

               if (doc.exists) {
                  final kidModel = KidModel.fromFirestore(doc, null);
                  _showEditKidModal(kidModel);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDeleteKid(kid),
            ),
          ]
        ],
      ),
    );
  }
}
