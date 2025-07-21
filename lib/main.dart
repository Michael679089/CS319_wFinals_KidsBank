import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wfinals_kidsbank/pages/login_page.dart';
import 'pages/welcomepage.dart';
import 'firebase_options.dart'; // auto-generated file by flutterfire CLI

void main() async {
  debugPrint("Initializing the firebase to the currentPlatform");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/welcome-page',
      routes: {
        '/welcome-page': (context) => const WelcomePage(),
        '/login-page': (context) => const LoginPage(),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Route Not Found')),
          body: Center(child: Text('No route defined for ${settings.name}')),
        ),
      ),
    );
  }
}
