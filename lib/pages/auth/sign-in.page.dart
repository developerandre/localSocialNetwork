import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:localsocialnetwork/strophe/core.dart';
import 'package:localsocialnetwork/pages/auth/auth.service.dart' as sign_in_service;
import 'package:localsocialnetwork/providers/xmpp.dart';
import 'package:localsocialnetwork/utils.dart';


class SignInPage extends StatefulWidget {
    final int step;
    final int code;
    final String phoneNumber;

    SignInPage({this.step: 1, this.code, this.phoneNumber});

    @override
    _SignInPageState createState() => new _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
    TextEditingController _phoneNumberController = new TextEditingController();
    TextEditingController _codeController = new TextEditingController();
    GlobalKey<ScaffoldState> _scaffold = new GlobalKey<ScaffoldState>();
    GlobalKey<FormState> _form = new GlobalKey<FormState>();
    XmppProvider _xmpp = XmppProvider.instance();
    double _linearProgressIndicatorValue = 0.0;
    String _password;

    @override
    Widget build(BuildContext context) => new Scaffold(
        key: _scaffold,
        appBar: new AppBar(
            title: new Text('Sign In'),
            actions: [
                new CircularProgressIndicator(
                    backgroundColor: Colors.red,
                )
            ],
        ),
        body: new SingleChildScrollView(
            child: new Column(
                children: [
                    new LinearProgressIndicator(
                        value: _linearProgressIndicatorValue,
                    ),
                    new Padding(
                        padding: new EdgeInsets.symmetric(horizontal: 16.0),
                        child: new Form(
                            key: _form,
                            child: new Column(
                                children: [
                                    new TextField(
                                        decoration: new InputDecoration(
                                            hintText: isStep1 ? 'Phone number' : 'Code',
                                        ),
                                        controller: isStep1 ? _phoneNumberController : _codeController,
                                        keyboardType: isStep1 ? TextInputType.phone : TextInputType.number,
                                        autofocus: true,
                                    ),
                                    new SizedBox(
                                        height: 5.0,
                                    ),
                                    new Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                            new FlatButton(
                                                child: new Text(isStep1 ? 'NEXT' : 'SIGN IN'),
                                                onPressed: () {
                                                    if (_form.currentState.validate()) {
                                                        isStep1 ? _getCode() : _getPassword();
                                                    }
                                                },
                                                textColor: Theme.of(context).primaryColor
                                            ),
                                        ],
                                    ),
                                ],
                            ),
                        )
                    ),
                ],
            )
        )
    );

    bool get isStep1 => widget.step == 1;

    void _getCode() {
        if (_linearProgressIndicatorValue == null) return;

        setState(() {
            _linearProgressIndicatorValue = null;
        });

        sign_in_service.getCode(_phoneNumberController.text).then((http.Response r) {
        var body = JSON.decode(r.body);
        print(body);

        Navigator.push(
            context,
            new MaterialPageRoute(
                builder: (_) => new SignInPage(
                    step: 2,
                    code: body['code'],
                    phoneNumber: _phoneNumberController.text,
                )
            )
        );
        })
        .catchError((e) {
            print(e);
        })
        .whenComplete(() {
            setState(() {
                _linearProgressIndicatorValue = 0.0;
            });
        });
    }

    void _getPassword() {
        if (_linearProgressIndicatorValue == null) return;

        setState(() {
            _linearProgressIndicatorValue = null;
        });

        sign_in_service.getPassword(widget.phoneNumber, _codeController.text)
        .then((http.Response r) {
            _password = JSON.decode(r.body)['password'];
            _signIn();
        })
        .catchError((e) {
            print(e);
        }).whenComplete(() {
            setState(() {
                _linearProgressIndicatorValue = 0.0;
            });
        });
    }

    @override
    void initState() {
        super.initState();

        if (widget.step == 2 && widget.code != null) {
         _codeController.text = widget.code.toString();
        }
    }

    void _signUp() {
        _xmpp.register(widget.phoneNumber).listen((ConnexionStatus status) {
            print('_signUp ${status.status} ${status.element} ${status.condition}');
            if (status.status == Strophe.Status['CONFLICT']) {
                _xmpp.connection.doDisconnect();
                _signIn();
            } else if (status.status == Strophe.Status['REGISTERED']) {
                _saveAccount();
            }
        });
    }

    void _signIn() {
        _xmpp.connect(widget.phoneNumber).listen((ConnexionStatus status) {
            print('_signIn ${status.status} ${status.element} ${status.condition}');
            if (status.status == Strophe.Status['AUTHFAIL']) {
                _xmpp.connection.doDisconnect();
                _signUp();
            }
        });
    }

    void _saveAccount() {
        SharedPreferences.getInstance().then((SharedPreferences preferences) {
            preferences.setString(AppPreferences.phoneNumber, widget.phoneNumber);
            preferences.setString(AppPreferences.password, _password);

            Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.contacts, (_) => false);
        })
        .catchError((e) {
            print(e);
        });
    }
}
