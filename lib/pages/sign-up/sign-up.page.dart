import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:localsocialnetwork/pages/sign-up/sign-up.service.dart' as signUpService;


class SignUpPage extends StatefulWidget {
    final int step;
    final int code;
    final String phoneNumber;

    SignUpPage({
        this.step: 1,
        this.code,
        this.phoneNumber
    });

    @override
    SignUpPageState createState() => new SignUpPageState();
}

class SignUpPageState extends State<SignUpPage> {
    TextEditingController _phoneNumberController = new TextEditingController();
    TextEditingController _codeController = new TextEditingController();
    GlobalKey<ScaffoldState> _scaffold = new GlobalKey<ScaffoldState>();

    @override
    Widget build(BuildContext context) => new Scaffold(
        key: _scaffold,
        appBar: new AppBar(
            title: new Text('Sign up step ${widget.step.toString()}'),
        ),
        body: new SingleChildScrollView(
            child: new Padding(
                padding: new EdgeInsets.all(16.0),
                child: new Column(
                    children: [
                        new TextField(
                            decoration: new InputDecoration(
                                hintText: isStep1 ? 'Phone number' : 'Code',
                            ),
                            controller: isStep1 ? _phoneNumberController : _codeController,
                            keyboardType: isStep1 ? TextInputType.phone : TextInputType.number,
                        ),
                        new SizedBox(
                            height: 5.0,
                        ),
                        new Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                                new FlatButton(
                                    child: new Text(isStep1 ? 'NEXT' : 'OK'),
                                    onPressed: isStep1 ? _getCode : _getPassword
                                )
                            ],
                        )
                    ],
                ),
            ),
        )
    );

    bool get isStep1 => widget.step == 1;

    void _getCode() {
        signUpService.getCode(_phoneNumberController.text)
        .then((http.Response r) {
            var body = JSON.decode(r.body);
            Navigator.push(context, new MaterialPageRoute(
                builder: (_) => new SignUpPage(
                    step: 2,
                    code: body['code'],
                    phoneNumber: _phoneNumberController.text,
                )
            ));
        })
        .catchError((e) {
            print(e);
        });
    }

    void _getPassword() {
        signUpService.getPassword(widget.phoneNumber, _codeController.text)
        .then((http.Response r) {
            var body = JSON.decode(r.body);
            print(body);

            SharedPreferences.getInstance()
            .then((SharedPreferences preferences) {
                preferences.setString('phoneNumber', widget.phoneNumber);
                preferences.setString('password', body['password']);
                print(preferences);

                Navigator.of(context).pushNamedAndRemoveUntil('/contacts', (_) => false);
            })
            .catchError((e) {
                print(e);
            });
        })
        .catchError((e) {
            print(e);
        });
    }

    @override
    void initState() {
        super.initState();

        if (widget.step == 2 && widget.code != null) {
            _codeController.text = widget.code.toString();
        }
    }
}
