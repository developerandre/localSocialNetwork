import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:localsocialnetwork/pages/contacts/contacts.page.dart';
import 'package:localsocialnetwork/pages/auth/sign-in.page.dart';
import 'package:localsocialnetwork/pages/account/account.page.dart';
import 'package:localsocialnetwork/utils.dart';


class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) => new MaterialApp(
        title: 'Local Social Network',
        debugShowCheckedModeBanner: false,
        routes: {
            AppRoutes.contacts: (_) => new ContactsPage(),
            AppRoutes.signIn: (_) => new SignInPage(),
            AppRoutes.account: (_) => new AccountPage(),
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
                        return new Scaffold(
                            body: new Center(
                                child: new CircularProgressIndicator(),
                            ),
                        );
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
        try {
            SharedPreferences preferences = await SharedPreferences.getInstance();

            return (
                preferences.getString(AppPreferences.phoneNumber) == null || 
                preferences.getString(AppPreferences.password) == null
            ) ? new SignInPage() : new ContactsPage();
        }
        catch (e) {
            print(e);
            return new Text(e.toString());
        }
    }
}
