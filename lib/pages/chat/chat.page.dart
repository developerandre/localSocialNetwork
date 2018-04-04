import 'package:flutter/material.dart';


class ChatPage extends StatefulWidget {
    final String title;

    ChatPage({this.title});

    @override
    ChatPageState createState() => new ChatPageState();
}

class ChatPageState extends State<ChatPage> {
    GlobalKey<ScaffoldState> _scaffold = new GlobalKey<ScaffoldState>();

    @override
    Widget build(BuildContext context) => new Scaffold(
        key: _scaffold,
        appBar: new AppBar(
            title: new Text(widget.title),
        ),
        body: new Column(
            children: [
                new Expanded(
                    child: new ListView.builder(
                        itemCount: 50,
                        itemBuilder: (_, int index) => _messageView(index),
                    )
                ),
                new Row(
                    children: [
                        new Expanded(
                            child: new TextField(
                                // maxLines: 2,
                                keyboardType: TextInputType.multiline,
                                decoration: new InputDecoration(
                                    hintText: 'Message',
                                    border: new OutlineInputBorder(
                                        borderRadius: new BorderRadius.circular(100.0),
                                        gapPadding: 0.0
                                    )
                                ),
                            ),
                        ),
                        new IconButton(
                            icon: new Icon(Icons.send),
                            onPressed: () {
                                print('send');
                            },
                        )
                    ],
                )
            ],
        )
    );

    @override
    void initState() {
        super.initState();
    }

    Widget _messageView(int index) {
        return new Text(index.toString());
    }
}
