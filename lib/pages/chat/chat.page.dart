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
            actions: [
                new PopupMenuButton(
                    itemBuilder: (_) => [
                        new PopupMenuItem(
                            value: 0,
                            child: new Text('Settings'),
                        )
                    ],
                    onSelected: (int value) {
                        print(value);
                    },
                )
            ],
        ),
        body: new Center(
            child: new Text('chat'),
        )
    );

    @override
    void initState() {
        super.initState();
    }
}
