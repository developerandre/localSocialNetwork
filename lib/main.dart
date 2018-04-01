import 'package:flutter/material.dart';
import 'package:localsocialnetwork/sign-up/sign-up.page.dart';
import 'package:localsocialnetwork/contacts/contacts.page.dart';


void main() => runApp(new MaterialApp(
    title: 'Local Social Network',
    theme: new ThemeData(
        primarySwatch: Colors.blue,
    ),
    home: new SignUpPage(1),
    routes: {
        '/contacts': (_) => new ContactsPage(),
        '/sign-up-step1': (_) => new SignUpPage(1),
        '/sign-up-step2': (_) => new SignUpPage(2),
    },
));
