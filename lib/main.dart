import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:wfinals_kidsbank/pages/login_page.dart';
import 'package:wfinals_kidsbank/pages/register_page.dart';
import 'package:wfinals_kidsbank/api/auth_service.dart';

import 'firebase_options.dart'; // And this import

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // Main Driver Class
  // Initializing Firebase Auth:
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Somewhere in your main or init function (only for debug/development)
  // FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  // FirebaseAuth.instance.useAuthEmulator('localhost', 9099);

  runApp(const MyApp()); // runs my MyApp class below...
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    debugPrint(authService.checkLoggedInUser().toString());

    return MaterialApp(debugShowCheckedModeBanner: false, home: LoginPage());
  }
}
