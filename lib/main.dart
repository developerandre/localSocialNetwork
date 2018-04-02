import 'package:flutter/material.dart';
import 'package:localsocialnetwork/app.dart';
import 'package:localsocialnetwork/providers/xmpp.dart';
import 'package:localsocialnetwork/strophe/plugins/register.dart';

void main() {
  XmppProvider instance =
      XmppProvider.instance(plugins: {'register': new RegisterPlugin()});
  instance.register("yesIam").listen((ConnexionStatus status) {});

  runApp(new MyApp());
}
