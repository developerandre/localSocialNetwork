import 'package:flutter/material.dart';


class NameDialogPage extends StatefulWidget {
    @override
    _NameDialogPageState createState() => new _NameDialogPageState();
}

class _NameDialogPageState extends State<NameDialogPage> {
    @override
    Widget build(BuildContext context) => new Scaffold(
        appBar: new AppBar(
            title: new Text('Change your name'),
            actions: [
                new IconButton(
                    icon: new Icon(Icons.check),
                    onPressed: () {
                        print('save');
                    },
                )
            ],
        ),
        body: new SingleChildScrollView(
            child: new Column(
                children: [
                    new Padding(
                        padding: new EdgeInsets.symmetric(horizontal: 16.0),
                        child: new Form(
                            child: new Column(
                                children: [
                                    new TextField(
                                        decoration: new InputDecoration(
                                            hintText: 'First name'
                                        ),
                                    ),
                                    new SizedBox(
                                        height: 5.0,
                                    ),
                                    new TextField(
                                        decoration: new InputDecoration(
                                            hintText: 'Last name'
                                        ),
                                    )
                                ],
                            ),
                        )
                    ),
                ],
            )
        )
    );
}
