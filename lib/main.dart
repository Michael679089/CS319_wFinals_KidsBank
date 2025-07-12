import 'package:firebase_core/firebase_core.dart';                  // Add this import
import 'package:flutter/material.dart';
import 'package:wfinals_kidsbank/pages/login.dart';
import 'api/fetchCurrentUser.dart';



import 'app.dart';
import 'firebase_options.dart';                                     // And this import

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await dotenv.load(fileName: "assets/.env");
  final clientId = dotenv.env['CLIENT_ID'];

  print(fetchPrintCurrentUserJSON()); // this will print if there's user.
  
  // we must redirect user to loginPage.
  
  runApp(LoginPage());
  // runApp(MyApp(clientId: clientId!)); // Use ! if you're sure it's not null
}