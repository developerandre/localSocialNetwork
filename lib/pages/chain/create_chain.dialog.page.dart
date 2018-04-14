import 'package:flutter/material.dart';
import '../../utils.dart';


class CreateChainDialog extends StatefulWidget {
    @override
    _CreateChainDialogState createState() => new _CreateChainDialogState();
}

class _CreateChainDialogState extends State<CreateChainDialog> {
    String _chainName;
    String _chainDescription;
    GlobalKey<FormState> _form = new GlobalKey();
    GlobalKey<ScaffoldState> _scaffold = new GlobalKey();

    @override
    Widget build(BuildContext context) => new Scaffold(
        key: _scaffold,
        appBar: new AppBar(
            title: new Text("Creating a chain"),
            actions: [
                new IconButton(
                    icon: new Icon(Icons.check),
                    onPressed: () {
                        if (_form.currentState.validate()) {
                            _form.currentState.save();
                            print(_chainName);
                            print(_chainDescription);
                        }
                    },
                )
            ],
        ),
        body: new Form(
            key: _form,
            child: new ListView(
                children: [
                    new ListTile(
                        leading: new GestureDetector(
                            child: new CircleAvatar(
                                child: new Text('A'),
                            ),
                            onTap: () {
                                Navigator.pushNamed(context, AppRoutes.avatar);
                            },
                        ),
                        title: new TextFormField(
                            decoration: new InputDecoration(
                                hintText: 'Chain name'
                            ),
                            validator: (String value) => value.isEmpty ? 'The chain name can not be empty' : null,
                            onSaved: (String value) {
                                _chainName = value;
                            },
                        ),
                    ),
                    new ListTile(
                        title: new TextFormField(
                            maxLines: 3,
                            decoration: new InputDecoration(
                                hintText: 'Description',
                            ),
                            onSaved: (String value) {
                                _chainDescription = value;
                            },
                        ),
                    ),
                ],
            ),
        ),
    );
}
