import 'package:flutter/material.dart';

// For Firebase Connection:
import 'package:firebase_core/firebase_core.dart';
import 'package:wfinals_kidsbank/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


void login() {

}



class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> { // The Widget Builder
  List<QueryDocumentSnapshot<Map<String, dynamic>>> firestoreDocs = [];

  @override
  void initState() {
    super.initState();
    fetchFirestoreData();
  }

  void fetchFirestoreData() async {
    final collection = FirebaseFirestore.instance.collection('TestCollection');
    final snapshot = await collection.get();

    setState(() {
      firestoreDocs = snapshot.docs;
    });
  }


  



  @override
  Widget build(BuildContext context) { 
    // NOTES: This Is Where We Buid the Projects Frontend:
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    // My Variables:
    const Color c1 = Color.fromARGB(255, 255, 0, 0); // red
    const FontWeight myFontWeight = FontWeight.w100;
    const FontStyle myFontStyle = FontStyle.italic;
    const TextBaseline myTextBaseLine = TextBaseline.alphabetic;
    const TextLeadingDistribution myTextLeadingDistribution = TextLeadingDistribution.proportional;
    const Locale myLocale = Locale("en", "PH"); // languageCode + countryCode
    const Shadow myShadow = Shadow(
      color: Color.fromARGB(255, 0, 0, 0),
      offset: Offset.zero,
      blurRadius: 0.0,
    );
    const List<Shadow> myListOfShadows = [myShadow, myShadow];
    const List<FontFeature> myFontFeatures = [FontFeature.enable("liga")];
    final myFormTextField = TextField(
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Enter a search term',
      ),
    );

    const Text myText = Text(
      'LOGIN',
      style: TextStyle(
        inherit: true,
        color: c1,
        backgroundColor: Color.fromARGB(0, 255, 0, 0),
        fontSize: 40.0,
        fontWeight: myFontWeight,
        fontStyle: myFontStyle,
        letterSpacing: 4.0,
        wordSpacing: 4.0,
        textBaseline: myTextBaseLine,
        height: 1.5,
        leadingDistribution: myTextLeadingDistribution,
        locale: myLocale,
        shadows: myListOfShadows,
        fontFeatures: myFontFeatures,
      ),
    );

    // ---------------

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          myText,
          const Text('E-Mail:'),
          myFormTextField,
          myFormTextField,
          const Text('Password:'),
          const Text('<PASSWORD TEXTBOX>'),
          const Text("SUBMIT BUTTON)"),
          const Divider(),
          const Text(
            "🔍 Firestore Test Output:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: firestoreDocs.length,
              itemBuilder: (context, index) {
                final doc = firestoreDocs[index];
                final id = doc.id;
                final data = doc.data();

                return ListTile(
                  title: Text('ID: $id'),
                  subtitle: Text(data.entries.map((e) => '${e.key}: ${e.value}').join('\n')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

