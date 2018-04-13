import 'package:flutter/material.dart';

class CreateCanal extends StatefulWidget {
  @override
  _CreateCanalState createState() => new _CreateCanalState();
}

class _CreateCanalState extends State<CreateCanal> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Créer une nouvelle page"),
      ),
    );
  }
}
