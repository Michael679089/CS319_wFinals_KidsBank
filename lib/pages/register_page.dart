import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:wfinals_kidsbank/api/auth_service.dart';
import 'package:wfinals_kidsbank/api/firestore_service.dart';
import 'package:wfinals_kidsbank/pages/login_page.dart';

import '../api/fetchCurrentUser.dart';

class Register_RoleSelector_Page extends StatelessWidget {
  const Register_RoleSelector_Page({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("You called RoleSelectPage.");

    return Scaffold(
      appBar: AppBar(title: Text('Select Role')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                debugPrint("user selected child");
                // Navigate back to Login Page.
                Navigator.pop(context);
              },
              child: Text('Register as Child'),
            ),
            ElevatedButton(
              onPressed: () {
                debugPrint("user selected parent");
                // Navigate to RegisterPage with selected role

                debugPrint("Redirecting to RegisterPage");
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _RegisterPage(selectedRole: "Parent"),
                  ),
                );
              },
              child: Text('Register as Parent'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterPage extends StatelessWidget {
  final String selectedRole;

  const _RegisterPage({super.key, required this.selectedRole});

  @override
  Widget build(BuildContext context) {
    debugPrint("You called RegisterPage.");

    var myFireStoreAPI = FirestoreAPI();
    myFireStoreAPI.initializeTheDatabase(); // Initialize the database

    var myFireAuthAPI = AuthService();

    var emailController = TextEditingController();
    var passController = TextEditingController();
    var familyNameController = TextEditingController();

    // MY Widget Variables:
    const Text myTitleText = const Text(
      'REGISTER PAGE',
      style: TextStyle(fontSize: 32),
    );

    SizedBox mySizedBox = SizedBox(height: 50);
    const Text myRegisterText = Text(
      'Already have an account? Click here',
      style: TextStyle(color: Colors.blueAccent),
    );

    TextField myFamilyNameTextField = TextField(
      controller: familyNameController,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Enter Family Name',
      ),
    );
    TextField myEmailTextField = TextField(
      controller: emailController,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Enter Email',
      ),
    );
    TextField myPassTextField = TextField(
      controller: passController,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Enter Password',
      ),
    );

    ElevatedButton submitBTN = ElevatedButton(
      onPressed: () async {
        String email = emailController.text.trim();
        String pass = passController.text.trim();
        String familyName = familyNameController.text.trim();

        debugPrint('email: $email');
        debugPrint('pass: $pass');

        if (email.isEmpty && pass.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('WARNING: Fields are empty')));
        } else if (email.isEmpty && pass.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('WARNING: Email is empty')));
        } else if (email.isNotEmpty && pass.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('WARNING: Pass is empty')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Registered!')));

          final UserCredential? myCreateAuthAccResponse = await myFireAuthAPI
              .createAccountToFirebaseAuth(
                email: email,
                password: pass,
                familyName: familyName,
              );
          if (myCreateAuthAccResponse != Null) {
            passController.text = "";
          }
        }
      },
      child: Text('Register'),
    );
    InkWell myTextLoginPageRedirect = InkWell(
      onTap: () {
        Navigator.pop(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      },
      child: Text(
        "Already have an account? Login Page here",
        style: TextStyle(color: Colors.blueAccent),
      ),
    );

    return Scaffold(
      body: Column(
        children: [
          myTitleText,
          myFamilyNameTextField,
          mySizedBox,
          myEmailTextField,
          mySizedBox,
          myPassTextField,
          mySizedBox,
          submitBTN,
          mySizedBox,
          myTextLoginPageRedirect,
        ],
      ),
    );
  }
}
