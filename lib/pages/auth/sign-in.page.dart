import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:localsocialnetwork/strophe/core.dart';
import 'package:localsocialnetwork/pages/auth/auth.service.dart' as signInService;
import 'package:localsocialnetwork/providers/xmpp.dart';
import 'package:localsocialnetwork/utils.dart';


class SignInPage extends StatefulWidget {
    final int step;
    final int code;
    final String phoneNumber;

    SignInPage({
        this.step: 1,
        this.code,
        this.phoneNumber
    });

    @override
    _SignInPageState createState() => new _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
    TextEditingController _textFieldPhoneNumberController = new TextEditingController();
    TextEditingController _textFieldCodeController = new TextEditingController();
    GlobalKey<ScaffoldState> _scaffold = new GlobalKey();
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
                        child: new Column(
                            children: [
                                new TextField(
                                    decoration: new InputDecoration(
                                        hintText: isStep1 ? 'Phone number' : 'Code',
                                    ),
                                    controller: isStep1 ? _textFieldPhoneNumberController : _textFieldCodeController,
                                    keyboardType: isStep1 ? TextInputType.phone : TextInputType.number,
                                ),
                                new SizedBox(
                                    height: 5.0,
                                ),
                                new Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                        new FlatButton(
                                            child: new Text(isStep1 ? 'NEXT' : 'SIGN IN'),
                                            onPressed: isStep1 ? _getCode : _getPassword,
                                            textColor: Theme.of(context).primaryColor
                                        ),
                                    ],
                                )
                            ],
                        ),
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

        signInService.getCode(_textFieldPhoneNumberController.text)
        .then((http.Response r) {
            var body = JSON.decode(r.body);

            Navigator.push(context, new MaterialPageRoute(
                builder: (_) => new SignInPage(
                    step: 2,
                    code: body['code'],
                    phoneNumber: _textFieldPhoneNumberController.text,
                )
            ));
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

        signInService.getPassword(widget.phoneNumber, _textFieldCodeController.text)
        .then((http.Response r) {
            _password = JSON.decode(r.body)['password'];
            _signUp();
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

    @override
    void initState() {
        super.initState();

        if (widget.step == 2 && widget.code != null) {
            _textFieldCodeController.text = widget.code.toString();
        }
    }

    void _signUp() {
        _xmpp.register(widget.phoneNumber)
        .listen((ConnexionStatus status) {
            print('ConnexionStatus: ${status.status}');

            if (status.status == Strophe.Status['CONFLICT']) {
                _signIn();
            }
            else if (status.status == Strophe.Status['REGISTERED']) {
                _saveAccount();
            }
        });
    }

    void _signIn() {
        _xmpp.connect(widget.phoneNumber)
        .listen((ConnexionStatus status) {
            print('ConnexionStatus: ${status.status}');
        });
    }

    void _saveAccount() {
        SharedPreferences.getInstance()
        .then((SharedPreferences preferences) {
            preferences.setString(AppPreferences.phoneNumber, widget.phoneNumber);
            preferences.setString(AppPreferences.password, _password);

            Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.contacts, (_) => false);
        })
        .catchError((e) {
            print(e);
        });
    }
}