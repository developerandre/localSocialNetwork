import 'dart:async';

import 'package:flutter/material.dart';
import 'package:localsocialnetwork/app.dart';
import 'package:localsocialnetwork/providers/store.dart';
import 'package:localsocialnetwork/providers/xmpp.dart';

void main() {
  StoreProvider.instance;
  XmppProvider instance = XmppProvider.instance();
  /* instance.connection.xmlInput = (elem) {
    print('xmlInput $elem');
  };

  instance.connection.xmlOutput = (elem) {
    print('xmlOutput $elem');
  }; */
  instance.connect("tonandre").listen((ConnexionStatus status) {
    print('connexion status ${status.status}');
  });
  runApp(new MyApp());
}
/* {ERROR: 0, CONNECTING: 1, CONNFAIL: 2, AUTHENTICATING: 3, AUTHFAIL: 4, CONNECTED: 5, DISCONNECTED: 6, DISCONNECTING: 7, ATTACHED: 8, REDIRECT: 9, CONNTIMEOUT: 10, REGIFAIL: 11, REGISTER: 12, REGISTERED: 13, CONFLICT: 14, NOTACCEPTABLE: 15} */
