import 'dart:async';

import 'package:localsocialnetwork/strophe/core.dart';
import 'package:localsocialnetwork/strophe/enums.dart';
import 'package:localsocialnetwork/strophe/plugins/bookmark.dart';
import 'package:localsocialnetwork/strophe/plugins/caps.dart';
import 'package:localsocialnetwork/strophe/plugins/disco.dart';
import 'package:localsocialnetwork/strophe/plugins/last-activity.dart';
import 'package:localsocialnetwork/strophe/plugins/muc.dart';
import 'package:localsocialnetwork/strophe/plugins/pep.dart';
import 'package:localsocialnetwork/strophe/plugins/plugins.dart';

import 'package:localsocialnetwork/strophe/plugins/chat-notifications.dart';
import 'package:localsocialnetwork/strophe/plugins/privacy.dart';
import 'package:localsocialnetwork/strophe/plugins/private-storage.dart';
import 'package:localsocialnetwork/strophe/plugins/pubsub.dart';
import 'package:localsocialnetwork/strophe/plugins/register.dart';
import 'package:localsocialnetwork/strophe/plugins/vcard-temp.dart';

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
  Map<String, PluginClass> _plugins = {
    'register': new RegisterPlugin(),
    'chatstates': new ChatStatesNotificationPlugin(),
    'vcard': new VCardTemp(),
    'private': new PrivateStorage(),
    'disco': new DiscoPlugin(),
    'muc': new MucPlugin(),
    'bookmarks': new BookMarkPlugin(),
    'pubsub': new PubsubPlugin(),
    'caps': new CapsPlugin(),
    'privacy': new PrivacyPlugin(),
    'pep': new PepPlugin(),
    'lastactivity': new LastActivity()
  };
  XmppProvider._();
  XmppProvider._internal([Map<String, PluginClass> plugins]) {
    _url = "ws://$_host:5280/xmpp";
    _mucService = "conference.$_domain";
    if (plugins != null) _plugins.addAll(plugins);
    _plugins.forEach((String name, PluginClass ptype) {
      Strophe.addConnectionPlugin(name, ptype);
    });
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

  String _formatToJid(String phone) {
    if (phone != null && phone.indexOf("@${this._domain}") != -1) {
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
getLastActivity(String jid){
  this._connection.lastactivity.getLastActivity(jid,(iq){

  },(err){});
}
  sendComposing(String jid, [String type = 'chat']) {
    jid = this._formatToJid(jid);
    this._connection.chatstates.sendComposing(jid, type);
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

  getvCard([String jid]) {
    this._connection.vcard.get(
        (iq) {
          print(iq);
        },
        jid,
        (iq) {
          print("error of getting vCard");
        });
  }

  getPrivate(
    String tag,
    String ns,
  ) {
    this._connection.private.get(tag, ns, (iq) {
      print(iq);
    }, (iq) {
      print("error of getting private storage");
    });
  }
createBookmarksNode(){
  this._connection.bookmarks.createBookmarksNode((iq){
print("$iq");
  },(err){
    print(err);
  });
}
addOrUpdateBookmark(String roomJid, String alias, String nick,[bool autojoin = true]){
   this._connection.bookmarks.add(roomJid,alias,nick,autojoin,(iq){
print("$iq");
  },(err){
    print(err);
  });
}
deleteBookmark(String roomJid){
   this._connection.bookmarks.delete(roomJid,(iq){
print("deleteBookmark $iq");
  },(err){
    print(err);
  });
}
getBookmarks(){
   this._connection.bookmarks.get((iq){
print("getBookmarks $iq");
  },(err){
    print('getBookmarks error $err');
  });
}
  discoveryItemsFor(String jid, [String node]) {
    this._connection.disco.items(jid, node, (iq) {
      print(iq);
    }, (err) {
      print(err);
    });
  }

  discoveryInfosFor(String jid, [String node]) {
    this._connection.disco.info(jid, node, (iq) {}, (err) {});
  }

  addDiscoveryItem(String jid, String name, String node, [Function callback]) {
    this._connection.disco.addItem(jid, name, node, callback);
  }

  removeFeature(String feature) {
    this._connection.disco.removeFeature(feature);
  }

  addFeature(String feature) {
    this._connection.disco.addFeature(feature);
  }

  addIdentity(String category, String type,
      [String name = '', String lang = '']) {
    this._connection.disco.addIdentity(category, type, name, lang);
  }

  disconnect([String reason = '']) {
    if (this._connection.connected) return;
    this._connection.disconnect(reason);
    this._connection = Strophe.Connection(this._url);
  }
}
