import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:localsocialnetwork/utils.dart';


class AccountPage extends StatefulWidget {
    @override
    _AccountPageState createState() => new _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
    @override
    Widget build(BuildContext context) => new Scaffold(
        appBar: new AppBar(
            title: new Text('Account')
        ),
        body: new ListView(
            children: ListTile.divideTiles(
                context: context,
                tiles: [
                    new ListTile(
                        title: new Text('Sign Out'),
                        onTap: () {
                            _signOut();
                        },
                    ),
                ]
            ).toList()
        )
    );

    void _signOut() {
        SharedPreferences.getInstance()
        .then((SharedPreferences preferences) {
            preferences.clear();
            Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.signIn, (_) => false);
        })
        .catchError((e) {
            print(e);
        });
    }
}
