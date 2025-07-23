import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wfinals_kidsbank/pages/kids_setup_page.dart';
import 'package:wfinals_kidsbank/pages/login_page.dart';
import 'package:wfinals_kidsbank/pages/parent_dashboard.dart';
import 'package:wfinals_kidsbank/pages/parent_setup_page.dart';
import 'package:wfinals_kidsbank/pages/register_account_page.dart';
import 'package:wfinals_kidsbank/pages/account_selector_page.dart';
import 'package:wfinals_kidsbank/pages/verirfy_email_page.dart';
import 'pages/welcomepage.dart';
import 'firebase_options.dart'; // auto-generated file by flutterfire CLI

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint(
    "Initialized the firebase to the currentPlatform ${DefaultFirebaseOptions.currentPlatform.appId}",
  );

  debugPrint("main.dart - redirecting user to welcomepage");
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
        '/register-page': (context) => const RegisterAccountPage(),
        '/verify-email-page': (context) => const VerificationEmailPage(),
        '/parent-setup-page': (context) => const ParentSetupPage(),
        '/kids-setup-page': (context) => const KidsSetupPage(),
        '/parent-dashboard-page': (context) => const ParentDashboard(),
        '/account-selector-page': (context) => const AccountSelectorPage(),
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
