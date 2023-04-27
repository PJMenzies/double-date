// import 'package:double_date/initial_setup.dart';
import 'package:double_date/week_form.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  String getUID() {
    return auth.FirebaseAuth.instance.currentUser?.uid ?? "";
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      initialRoute: auth.FirebaseAuth.instance.currentUser == null ? '/sign-in' : '/profile',
      routes: {
        '/sign-in': (context) => SignInScreen( // found in https://github.com/firebase/flutterfire/blob/master/packages/firebase_ui_auth/doc/providers/email.md
            actions: [
              AuthStateChangeAction<SignedIn>((context, state) {
                Navigator.pushNamed(context, '/profile');
              }),
            ],
          ),
        '/profile': (context) => ExampleForm(userID: getUID()),
        '/verify-email': (context) => ExampleForm(userID: getUID()),
      },
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
    );
  }
}

