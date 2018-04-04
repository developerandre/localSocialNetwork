import 'dart:async';

import 'package:localsocialnetwork/strophe/core.dart';
import 'package:localsocialnetwork/strophe/enums.dart';
import 'package:localsocialnetwork/strophe/plugins/plugins.dart';

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
  String _host = '192.168.43.45';
  String _domain = "localhost";
  String _pass = "jesuis123";
  String _jid;
  String _url;

  XmppProvider._();
  XmppProvider._internal(Map<String, PluginClass> plugins) {
    _url = "ws://$_host:5280/xmpp";
    _mucService = "conference.$_domain";
    if (plugins != null && plugins.length > 0) {
      plugins.forEach((String name, PluginClass ptype) {
        Strophe.addConnectionPlugin(name, ptype);
      });
    }
    _connection = Strophe.Connection(_url);
  }
  StropheConnection get connection {
    return _connection;
  }

  String get pass {
    return _pass;
  }

  String get jid {
    return _jid;
  }

  set jid(String id) {
    if (id != null && id.indexOf("@$_domain") != -1) _jid = id;
  }

  set pass(String pwd) {
    if (pwd != null) _pass = pwd;
  }

  static XmppProvider instance({Map<String, PluginClass> plugins}) {
    if (_instance == null) {
      _instance = new XmppProvider._internal(plugins);
    }
    return _instance;
  }

  _formatToJid(String phone) {
    if (phone != null && phone.indexOf("@{this._domain}") != -1) {
      return phone;
    }
    return "$phone@${this._domain}";
  }

  Stream<ConnexionStatus> connect(String phone) {
    StreamController<ConnexionStatus> streamController =
        new StreamController<ConnexionStatus>();
    String jid = this._formatToJid(phone);
    if (this._pass == null ||
        this._pass.isEmpty ||
        jid == null ||
        jid.isEmpty) {
      streamController.addError(
          "Le numéro de téléphone ou le mot de passe n'est pas renseigné");
      streamController.close();
      return streamController.stream;
    }
    _connection.connect(jid, this._pass, (int status, condition, ele) {
      streamController.add(new ConnexionStatus(status, condition, ele));
      if (status == Strophe.Status['CONNECTED']) {
        this.jid = jid;
        this.handleAfterConnect();
        streamController.close();
      } else if (status == Strophe.Status['DISCONNECTED'])
        streamController.close();
    });
    return streamController.stream;
  }

  Stream<ConnexionStatus> register(String phone) {
    StreamController<ConnexionStatus> streamController =
        new StreamController<ConnexionStatus>();
    if (this._connection.register == null) {
      streamController.addError("Le plugin register n'est disponible");
      streamController.close();
      return streamController.stream;
    }
    this._connection.register.connect(this._domain,
        (int status, condition, ele) {
      streamController.add(new ConnexionStatus(status, condition, ele));
      if (status == Strophe.Status['REGISTER']) {
        print('register');
        this._connection.register.fields['username'] = phone;
        this._connection.register.fields['password'] = this._pass;
        this._connection.register.fields['name'] = phone;
        this._connection.register.fields['email'] = "";
        this._connection.register.submit();
      } else if (status == Strophe.Status['REGISTERED']) {
        print("registered!");
        this.jid = _formatToJid(phone);
        this._connection.authenticate(null);
      } else if (status == Strophe.Status['CONFLICT']) {
        print("Contact already existed!");
      } else if (status == Strophe.Status['NOTACCEPTABLE']) {
        print("Registration form not properly filled out.");
      } else if (status == Strophe.Status['REGIFAIL']) {
        print(
            "The Server does not support In-Band Registration $condition $ele");
      } else if (status == Strophe.Status['CONNECTED']) {
        print('is connected');
        this.handleAfterConnect();
      }
    });
    return streamController.stream;
  }

  handleAfterConnect() {
    this.sendPresence();
    this.getRoster();
    this.handlePresence();
    this.handleMessage();
    this.handleGroupMessage();
    this.handleNormalMessage();
  }

  void getRoster() {}
  void handlePresence() {
    this._connection.addHandler((presence) {
      print(presence);
      return true;
    }, null, 'presence');
  }

  void handleGroupMessage() {
    this._connection.addHandler((msg) {
      print(msg);
      return true;
    }, null, 'message', 'groupchat');
  }

  void handleMessage() {
    this._connection.addHandler((msg) {
      print(msg);
      return true;
    }, null, 'message', 'chat');
  }

  void handleNormalMessage() {
    this._connection.addHandler((msg) {
      print(msg);
      return true;
    }, null, 'message', 'normal');
  }

  sendPresence() {
    if (!this._connection.connected) return;
    _connection.sendPresence(Strophe.$pres().tree());
  }

  sendComposing(String jid, [String type = 'chat']) {
    jid = this._formatToJid(jid);
    //this._connection.chatstates.sendComposing(jid, type);
  }

  sendMessage(String jid, String message,
      {String userName = '', String blockquote = '', String type = 'chat'}) {
    if (!this._connection.connected) return;
    jid = this._formatToJid(jid);
    StanzaBuilder msg = Strophe
        .Builder('message', attrs: {'to': jid, 'from': this.jid, 'type': type});
    msg
        .c('subject')
        .t(userName ?? jid)
        .up()
        .c('html', {'xmlns': 'http://jabber.org/protocol/xhtml-im'}).c(
            'body', {'xmlns': 'http://www.w3.org/1999/xhtml'});
    if (blockquote != null && blockquote.isNotEmpty)
      msg.c('blockquote').t(blockquote).up();
    String now = new DateTime.now().millisecondsSinceEpoch.toString();
    msg.c('p', {'date': now, 'id': now}).t(message.toString()).up();
    this._connection.send(msg.tree());
  }

  disconnect([String reason = '']) {
    if (this._connection.connected) return;
    this._connection.disconnect(reason);
    this._connection = Strophe.Connection(this._url);
  }
}
