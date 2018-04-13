import 'package:flutter/material.dart';


class ProfilePicturePage extends StatefulWidget {
    @override
    _ProfilePicturePageState createState() => new _ProfilePicturePageState();
}

class _ProfilePicturePageState extends State<ProfilePicturePage> {
    @override
    Widget build(BuildContext context) => new Scaffold(
        appBar: new AppBar(
            title: new Text('Profile picture'),
            actions: [
                new IconButton(
                    icon: new Icon(Icons.create),
                    onPressed: () {
                        print('update avatar');
                    },
                )
            ],
        ),
        body: new Center(
            child: new Image.asset('assets/images/avatar.jpg')
        )
    );
}
