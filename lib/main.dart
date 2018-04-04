import 'package:flutter/material.dart';
import 'package:localsocialnetwork/app.dart';
import 'package:localsocialnetwork/providers/xmpp.dart';

void main() {
  XmppProvider instance = XmppProvider.instance();
  instance.connection.xmlInput = (elem) {
    print('xmlInput $elem');
  };
  instance.connection.xmlOutput = (elem) {
    print('xmlOutput $elem');
  };
  instance.connect("tonandre").listen((ConnexionStatus status) {});

  runApp(new MyApp());
}
