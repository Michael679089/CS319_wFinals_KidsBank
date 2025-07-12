import 'package:firebase_core/firebase_core.dart';                  // Add this import
import 'package:flutter/material.dart';
import 'package:wfinals_kidsbank/pages/login_page.dart';
import 'api/fetchCurrentUser.dart';


import 'firebase_options.dart';                                     // And this import

import 'package:flutter_dotenv/flutter_dotenv.dart';



Future<void> main() async { // Main Driver Class
  // Initializing Firebase Auth:
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print(fetchPrintCurrentUserJSON()); // this will print if there's user.
  runApp(const MyApp()); // runs my MyApp class below...
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}