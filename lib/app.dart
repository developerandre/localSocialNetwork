import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:localsocialnetwork/pages/contacts/contacts.page.dart';
import 'package:localsocialnetwork/pages/sign-up/sign-up.page.dart';


class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) => new MaterialApp(
        title: 'Local Social Network',
        debugShowCheckedModeBanner: false,
        routes: {
            '/contacts': (_) => new ContactsPage(),
            '/sign-up': (_) => new SignUpPage(),
        },
        theme: new ThemeData(
            primarySwatch: Colors.blue,
        ),
        home: new FutureBuilder(
            future: _getHomePage(),
            builder: (_, AsyncSnapshot<Widget> snapshot) {
                switch (snapshot.connectionState) {
                    case ConnectionState.done:
                        return snapshot.hasError ? new Text('hasError') : snapshot.data;
                    break;
                    case ConnectionState.waiting:
                        return new Text('waiting');
                    break;
                    case ConnectionState.active:
                        return new Text('active');
                    break;
                    case ConnectionState.none:
                        return new Text('none');
                    break;
                    default:
                        return new Text('default');
                }
            },
            initialData: new Text('...')
        )
    );

    Future<Widget> _getHomePage() async {
        SharedPreferences preferences = await SharedPreferences.getInstance();

        if (preferences.getString('phoneNumber') == null || preferences.getString('password') == null)
            return new SignUpPage();
        else return new ContactsPage();
    }
}
