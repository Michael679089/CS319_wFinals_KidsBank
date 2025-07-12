import 'package:flutter/material.dart';

// For Firebase Connection:
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wfinals_kidsbank/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wfinals_kidsbank/pages/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  // My Elemental Variables:
  final TextEditingController _controller = TextEditingController();
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debugValue = true;

    // My Widget Variables:
    const Text myTitleText = const Text( 
      'LOGIN PAGE', 
      style: TextStyle(fontSize: 32),
    );

    const Text myText = const Text( 
      'Enter your name:', 
      style: TextStyle(fontSize: 18),
    );

    TextField myTextField = TextField(
      controller: _controller,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Type here',
      ),
    );

    ElevatedButton myElevatedBTN = ElevatedButton(
      onPressed: () {
        final input = _controller.text;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Submitted'),
            content: Text('You entered: $input'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              )
            ],
          ),
        );
      },
      child: const Text('Submit'),
    );

    ElevatedButton myRegisterTeleporterBTN = ElevatedButton(
      onPressed: () {
        debugPrint("Redirecting to Register Page.");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterPage()
          ),
        );
      },
      child: const Text('Register a new account!'),
    );
    
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          myTitleText,
          myText,
          const SizedBox(height: 10),
          myTextField,
          const SizedBox(height: 10),
          myElevatedBTN,
          const SizedBox(height: 10),
          myRegisterTeleporterBTN
        ],)
    );
  }
}
