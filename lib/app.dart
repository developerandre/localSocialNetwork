import 'package:flutter/material.dart';
import 'package:localsocialnetwork/contacts/contacts.page.dart';
import 'package:localsocialnetwork/sign-up/sign-up.page.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Local Social Network',
      debugShowCheckedModeBanner: false,
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new SignUpPage(1),
      routes: {
        '/contacts': (_) => new ContactsPage(),
        '/sign-up-step1': (_) => new SignUpPage(1),
        '/sign-up-step2': (_) => new SignUpPage(2),
      },
    );
  }
}
