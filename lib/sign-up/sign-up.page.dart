import 'package:flutter/material.dart';


class SignUpPage extends StatefulWidget {
    final int step;

    SignUpPage(this.step);

    @override
    State<SignUpPage> createState() => new SignUpPageState();
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
        body: new Padding(
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
                                onPressed: isStep1 ? _requestCode : _confirmCode
                            )
                        ],
                    )
                ],
            ),
        ),
    );

    bool get isStep1 => widget.step == 1;

    void _requestCode() {
        print(_phoneNumberController.text);
        Navigator.of(context).pushNamed('/sign-up-step2');
    }

    void _confirmCode() {
        print(_codeController.text);
        Navigator.of(context).pushNamedAndRemoveUntil('/contacts', (_) => false);
    }
}
