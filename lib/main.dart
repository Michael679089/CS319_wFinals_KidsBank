import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wfinals_kidsbank/pages/create_kids_account_page.dart';
import 'package:wfinals_kidsbank/pages/k_dashboard.dart';
import 'package:wfinals_kidsbank/pages/k_dashboard_chores_page.dart';
import 'package:wfinals_kidsbank/pages/k_dashboard_notification_page.dart';
import 'package:wfinals_kidsbank/pages/k_login_page.dart';
import 'package:wfinals_kidsbank/pages/k_setup_page.dart';
import 'package:wfinals_kidsbank/pages/login_page.dart';
import 'package:wfinals_kidsbank/pages/p_dashboard_chores_page.dart';
import 'package:wfinals_kidsbank/pages/p_dashboard_notification_page.dart';
import 'package:wfinals_kidsbank/pages/p_dashboard.dart';
import 'package:wfinals_kidsbank/pages/p_login_page.dart';
import 'package:wfinals_kidsbank/pages/p_setup_page.dart';
import 'package:wfinals_kidsbank/pages/register_account_page.dart';
import 'package:wfinals_kidsbank/pages/account_selector_page.dart';
import 'package:wfinals_kidsbank/pages/verify_email_page.dart';
import 'pages/welcomepage.dart';
import 'firebase_options.dart'; // auto-generated file by flutterfire CLI

const bool isUnauthenticatedDebug = bool.fromEnvironment('DEBUG_UNAUTHENTICATED', defaultValue: false);
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint("Initialized the firebase to the currentPlatform ${DefaultFirebaseOptions.currentPlatform.appId}");

  if (isUnauthenticatedDebug) {
    // Force unauthenticated state
    FirebaseAuth.instance.signOut();
    debugPrint("main.dart - unauthenticated debug is active.");
  }

  debugPrint("main.dart - redirecting user to welcomepage");
  runApp(const MyApp());
}

class MissingRouteArgumentException implements Exception {
  final String routeName;
  final List<String> missingArgs;

  MissingRouteArgumentException(this.routeName, this.missingArgs);

  @override
  String toString() => 'Missing required arguments for $routeName: $missingArgs';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // I have 19 pages in this project. There should only be 19 routes.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/welcome-page',
      routes: {
        '/welcome-page': (context) => const WelcomePage(),
        '/login-page': (context) => const LoginPage(),
        '/parent-setup-page': (context) => const ParentSetupPage(),
        '/kids-login-page': (context) => const KidsLoginPage(),
      },
      onGenerateRoute: (settings) {
        Widget page;
        final args = settings.arguments as Map<String, dynamic>? ?? {};

        // Helper function to validate required arguments
        void validateArgs(String routeName, List<String> requiredKeys) {
          final missingArgs = requiredKeys.where((key) => !args.containsKey(key) || args[key] == null || args[key] == '').toList();
          if (missingArgs.isNotEmpty) {
            throw MissingRouteArgumentException(routeName, missingArgs);
          }
        }

        try {
          switch (settings.name) {
            case '/register-page':
              validateArgs(settings.name as String, ["is-broken-register"]);
              page = RegisterAccountPage(is_broken_register: args["is-broken-register"]);
              break;
            case '/verify-email-page':
              validateArgs(settings.name as String, ["new-family-model", "new-family-payment-info-model"]);
              page = VerificationEmailPage(newFamilyModel: args["new-family-model"], newFamilyPaymentInfoModel: args["new-family-payment-info-model"]);
              break;
            case '/account-selector-page':
              validateArgs(settings.name as String, ["user-id"]);
              page = AccountSelectorPage(user_id: args["user-id"]);
              break;

            // Below will be the Pages of Kids
            // case '/kids-setup-page':
            //   validateArgs('/kids-setup-page', [
            //     'parent-id',
            //     'came-from-parent-dashboard',
            //   ]);
            //   page = KidsSetupPage(
            //     parentId: args['parent-id'],
            //     cameFromParentDashboard:
            //         args['came-from-parent-dashboard'] ?? false,
            //   );
            //   break;
            // case '/kids-dashboard-page':
            //   validateArgs('/kids-dashboard-page', [
            //     'kid-id',
            //     'family-user-id',
            //   ]);
            //   page = KidsDashboard(
            //     kidId: args['kid-id'],
            //     familyUserId: args['family-user-id'],
            //   );
            //   break;
            // case '/kids-notifications-page':
            //   validateArgs('/kids-notifications-page', [
            //     'kid-id',
            //     'family-user-id',
            //   ]);
            //   page = KidsNotificationsPage(
            //     kidId: args['kid-id'],
            //     familyUserId: args['family-user-id'],
            //   );
            //   break;
            // case '/kids-chores-page':
            //   validateArgs('/kids-chores-page', ['kid-id', 'family-user-id']);
            //   page = KidsChoresPage(
            //     kidId: args['kid-id'],
            //     familyUserId: args['family-user-id'],
            //   );
            //   break;
            // case '/create-kids-account-page':
            //   validateArgs('/create-kids-account-page', [
            //     'parent-id',
            //     'family-user-id',
            //   ]);
            //   page = CreateKidAccountPage(
            //     parentId: args['parent-id'],
            //     familyUserId: args['family-user-id'],
            //   );
            //   break;

            // Below will be the pages of Parents.
            // case '/parent-login-page':
            //   validateArgs(settings.name as String, ["family-user-id"]);
            //   page = ParentLoginPage(familyId: args["family-user-id"]);
            //   break;
            // case '/parent-dashboard-page':
            //   validateArgs('/parent-dashboard-page', [
            //     'family-user-id',
            //     'parent-id',
            //   ]);
            //   page = ParentDashboard(
            //     familyUserId: args['family-user-id'],
            //     parentId: args['parent-id'],
            //   );
            //   break;
            // case '/parent-notifications-page':
            //   validateArgs('/parent-notifications-page', [
            //     'family-user-id',
            //     'parent-id',
            //   ]);
            //   page = ParentNotificationsPage(
            //     familyUserId: args['family-user-id'],
            //     parentId: args['parent-id'],
            //   );
            //   break;
            // case '/parent-chores-page':
            //   validateArgs('/parent-chores-page', [
            //     'family-user-id',
            //     'parent-id',
            //   ]);
            //   page = ParentChoresPage(
            //     familyUserId: args['family-user-id'],
            //     parentId: args['parent-id'],
            //   );
            //   break;
            // case '/create-kid-account-page':
            //   validateArgs('/create-kid-account-page', [
            //     'family-user-id',
            //     'parent-id',
            //   ]);
            //   page = CreateKidAccountPage(
            //     familyUserId: args['family-user-id'],
            //     parentId: args['parent-id'],
            //   );
            //   break;
            default:
              page = Scaffold(
                appBar: AppBar(title: const Text('Route Not Found')),
                body: Center(child: Text('No route defined for ${settings.name}')),
              );
          }
          return MaterialPageRoute(builder: (_) => page, settings: settings);
        } catch (e) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Navigation Error')),
              body: Center(child: Text('Error: $e')),
            ),
          );
        }
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
