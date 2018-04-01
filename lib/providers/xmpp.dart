import 'dart:async';

import 'package:localsocialnetwork/strophe/core.dart';
import 'package:localsocialnetwork/strophe/enums.dart';

class ConnexionStatus {
  int status;
  String condition;
  var element;
  ConnexionStatus(this.status, this.condition, this.element);
}

class XmppProvider {
  static XmppProvider _instance;
  String _mucService = '';
  StropheConnection _connection;
  String _host = '192.168.8.101';
  String _domain = "localhost";
  String _pass = "jesuis123";
  String _jid;
  String _url;

  XmppProvider._();
  XmppProvider._internal() {
    _url = "ws://$_host:5280/xmpp";
    _mucService = "conference.$_host";
    _connection = Strophe.Connection(_url);
  }
  String get pass {
    return _pass;
  }

  String get jid {
    return _jid;
  }

  set jid(String id) {
    if (id != null) _jid = id;
  }

  set pass(String pwd) {
    if (pwd != null) _pass = pwd;
  }

  static XmppProvider get instance {
    if (_instance == null) {
      _instance = new XmppProvider._internal();
    }
    return _instance;
  }

  formatToJid(String phone) {
    if (phone != null && phone.indexOf("@{this._domain}") != -1) {
      return phone;
    }
    return "$phone@${this._domain}";
  }

  Stream<ConnexionStatus> connect(String phone) {
    StreamController<ConnexionStatus> streamController =
        new StreamController<ConnexionStatus>();
    print(this.formatToJid(phone));
    _connection.connect(this.formatToJid(phone), this._pass,
        (int status, condition, ele) {
      streamController.add(new ConnexionStatus(status, condition, ele));
      if (status == Strophe.Status['CONNECTED']) {
        this.sendPresence();
        streamController.close();
      } else if (status == Strophe.Status['DISCONNECTED'])
        streamController.close();
    });
    return streamController.stream;
  }

  sendPresence() {
    _connection.sendPresence(Strophe.$pres().tree());
  }
}
