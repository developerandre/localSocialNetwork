import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/xmpp.dart';
import '../../utils.dart';
import './name.dialog.page.dart';


class AccountPage extends StatefulWidget {
    @override
    _AccountPageState createState() => new _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
    XmppProvider _xmpp = XmppProvider.instance();

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
                        leading: new GestureDetector(
                            child: new CircleAvatar(
                                child: new Text('A'),
                            ),
                            onTap: () {
                                Navigator.pushNamed(context, AppRoutes.avatar);
                            },
                        ),
                        title: new Text('Abc DEF'),
                        subtitle: new Text('+00000000000'),
                        trailing: new IconButton(
                            icon: new Icon(Icons.create),
                            onPressed: () {
                                Navigator.push(context, new MaterialPageRoute(
                                    builder: (_) => new NameDialogPage(),
                                    fullscreenDialog: true,
                                ));
                            },
                        ),
                    ),
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
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext ctx) => new AlertDialog(
                content: new Text('Sign out ?'),
                actions: [
                    new FlatButton(
                        child: new Text('CANCEL'),
                        onPressed: () {
                            Navigator.pop(ctx);
                        },
                    ),
                    new FlatButton(
                        child: new Text('SIGN OUT'),
                        onPressed: () {
                            _xmpp.disconnect();

                            SharedPreferences.getInstance()
                            .then((SharedPreferences preferences) {
                                preferences.clear();
                                Navigator.of(ctx).pushNamedAndRemoveUntil(AppRoutes.signIn, (_) => false);
                            })
                            .catchError((e) {
                                print(e);
                            });
                        },
                        
                    ),
                ],
            )
        );
    }
}
