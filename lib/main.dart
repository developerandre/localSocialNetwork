import 'package:flutter/material.dart';
import 'package:localsocialnetwork/app.dart';
import 'package:localsocialnetwork/providers/xmpp.dart';
import 'package:localsocialnetwork/strophe/core.dart';

void main() {
  XmppProvider instance = XmppProvider.instance;
  instance.connect("tonandre").listen((ConnexionStatus status) {
    if (status.status == Strophe.Status['CONNECTING']) {
      print('Strophe is connecting: ' + status.status.toString());
    } else if (status.status == Strophe.Status['CONNECTED']) {
      print('Strophe is connected: ' + status.toString());
    } else if (status.status == Strophe.Status['DISCONNECTING']) {
      print('Strophe is disconnecting. ' +
          status.toString() +
          ", condition: $status.condition");
    } else if (status.status == Strophe.Status['DISCONNECTED']) {
      print('Connection disconnected ' +
          status.toString() +
          ", condition: $status.condition");
    } else if (status.status == Strophe.Status['CONNFAIL']) {
      print('Strophe failed to connect. ' +
          status.toString() +
          ", condition: $status.condition");
    } else if (status.status == Strophe.Status['ERROR']) {
      print('Strophe error. ' +
          status.toString() +
          ", condition: $status.condition");
    } else if (status.status == Strophe.Status['AUTHENTICATING']) {
      print('Strophe authenticating. ' +
          status.toString() +
          ", condition: $status.condition");
    } else if (status.status == Strophe.Status['AUTHFAIL']) {
      print('Strophe auth fail.' +
          status.toString() +
          ", condition: $status.condition");
    } else if (status.status == Strophe.Status['ATTACHED']) {
      print('Strophe attached. ' +
          status.toString() +
          ", condition: $status.condition");
    }
  });
  runApp(new MyApp());
}
