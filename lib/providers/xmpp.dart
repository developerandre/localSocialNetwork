import 'dart:async';

import 'package:localsocialnetwork/strophe/core.dart';
import 'package:localsocialnetwork/strophe/enums.dart';
import 'package:localsocialnetwork/strophe/plugins/administration.dart';
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
  String _host = '192.168.43.45';
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
    'admin': new AdministrationPlugin(),
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

  String _formatToJid(String phone, [String domain]) {
    if (domain != null || domain.isEmpty) domain = this._domain;
    if (phone != null && phone.indexOf("@$domain") != -1) {
      return phone;
    }
    return "$phone@$domain";
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
      if (!streamController.isClosed)
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
      if (!streamController.isClosed)
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
    this.unsubscribeToPep("myNode2");
    this.getRoster();
    this.handlePresence();
    this.handleMessage();
    this.handleGroupMessage();
    this.handleNormalMessage();
  }

  void getRoster() {}
  void handlePresence() {
    this._connection.addHandler((presence) {
      print(presence.runtimeType);
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

  getLastActivity(String jid) {
    this._connection.lastactivity.getLastActivity(jid, (iq) {}, (err) {});
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

  getRegisteredUsersNum() {
    this._connection.admin.getRegisteredUsersNum((iq) {}, (error) {});
  }

  getOnlineUsersNum() {
    this._connection.admin.getOnlineUsersNum((iq) {}, (error) {});
  }

  createCanal(String node) {
    Map<String, String> config = {
      'pubsub#title': node,
      'pubsub#deliver_notifications': '1',
      'pubsub#deliver_payloads': '1',
      'pubsub#persist_items': '1',
      'pubsub#presence_based_delivery': 'true',
      'pubsub#notify_delete': '1',
      'pubsub#send_last_published_item': 'on_sub_and_presence'
    };
    this._connection.pubsub.createNode(node, config, (result) {});
  }

  getDefaultCanalConfig() {
    this._connection.pubsub.getDefaultNodeConfig((iq) {});
  }

  getCanalCanalConfig(String node) {
    this._connection.pubsub.getConfig(node, (iq) {});
  }

  discoverCanals() {
    this._connection.pubsub.discoverNodes((iq) {}, (iq) {});
  }

  getCanalItems(String node) {
    this._connection.pubsub.items(node, (iq) {}, (iq) {});
  }

  publishCanalItems(String node, List<Map<String, dynamic>> items) {
    this._connection.pubsub.publish(node, items, (iq) {});
  }

  getSubscriptionsOfUserJid() {
    this._connection.pubsub.getSubscriptions((iq) {});
  }

  getCanalAffiliations(String node) {
    this._connection.pubsub.getAffiliations(node, (iq) {});
  }

  setCanalAffiliations(String node, String jid, String affiliation) {
    this._connection.pubsub.setAffiliation(node, jid, affiliation, (iq) {});
  }

  subscribeToCanal(String node) {
    this._connection.pubsub.subscribe(node, null, (evt) {}, (iq) {});
  }

  unsubscribeToCanal(String node, String jid) {
    this._connection.pubsub.unsubscribe(node, jid, null, (iq) {}, (err) {});
  }

  getCanalSubscriptions(String node) {
    this._connection.pubsub.getNodeSubscriptions(node, (iq) {});
  }

  deleteCanal(String node) {
    this._connection.pubsub.deleteNode(node, (iq) {});
  }

  publishPepItems(String node, List<Map<String, dynamic>> items) {
    this._connection.pep.publish(node, items, (iq) {});
  }

  subscribeToPep(String node) {
    this._connection.pep.subscribe(node, (iq) {});
  }

  unsubscribeToPep(String node) {
    this._connection.pep.unsubscribe(node);
  }

  getPrivacyListNames() {
    this
        ._connection
        .privacy
        .getListNames((iq) {}, (error) {}, (listChangeIq) {});
  }

  loadPrivacyList(String name) {
    if (name == null || name.isEmpty) return;
    this._connection.privacy.loadList(name, (iq) {}, (error) {});
  }

  savePrivacyList(String name) {
    if (name == null || name.isEmpty) return;
    this._connection.privacy.saveList(name, (iq) {}, (error) {});
  }

  setActivePrivacyList(String name) {
    if (name == null || name.isEmpty) return;
    this._connection.privacy.setActive(name, (iq) {}, (error) {});
  }

  setDefaultPrivacyList(String name) {
    if (name == null || name.isEmpty) return;
    this._connection.privacy.setDefault(name, (iq) {}, (error) {});
  }

  deletePrivacyList(String name) {
    if (name == null || name.isEmpty) return;
    this._connection.privacy.deleteList(name, (iq) {}, (error) {});
  }

  PrivacyList newPrivacyList(String name) {
    if (name == null || name.isEmpty) return null;
    return this._connection.privacy.newList(name);
  }

  PrivacyItem newPrivacyListItem(String type, String value, String action,
      int order, List<String> blocked) {
    if (type == null || type.isEmpty || value == null || value.isEmpty)
      return null;
    return this
        ._connection
        .privacy
        .newItem(type, value, action, order, blocked);
  }

  getvCard([String jid]) {
    this._connection.vcard.get(
        (iq) {
          print("getvCard: $iq");
        },
        jid,
        (iq) {
          print("error of getting vCard");
        });
  }

  setvCard(VCardEl ele, [String jid]) {
    this._connection.vcard.set(
        (iq) {
          print(iq);
        },
        ele,
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

  setPrivate(String tag, String ns, data) {
    this._connection.private.set(tag, ns, data, (iq) {
      print(iq);
    }, (iq) {
      print("error of getting private storage");
    });
  }

  listRooms() {
    if (!this._connection.connected) return;
    this._connection.muc.listRooms(this._mucService, (iq) {
      // print('iq rooms');
      // print(iq);
    }, (iqError) {
      // print('iqError rooms');
      // print(iqError);
    });
  }

  joinGroup(String name, String nick) {
    if (!this._connection.connected) return;
    nick = nick ?? Strophe.getNodeFromJid(this.jid);
    if (name == null || name.isEmpty || nick == null || nick.isEmpty) return;

    name = name.replaceAll(new RegExp(' '), '_');
    name = name.replaceAll(new RegExp('[éèêë]'), 'e');
    name = name.replaceAll(new RegExp('[ùûü]'), 'u');
    name = name.replaceAll(new RegExp('[îï]'), 'i');
    name = name.replaceAll(new RegExp('[àâä]'), 'a');
    name = name.toLowerCase();
    nick = nick.toLowerCase();
    String room = this._formatToJid(name, this._mucService);
    // print('joining room', room);
    this._connection.muc.join(room, nick, (msg) {
      // print('group message');
      // print(msg);
    }, (pres) {
      // print('group presence');
      // print(pres);
    }, (roster) {
      // print('group roster');
      // print(roster);
    });
  }

  multipleInvites(String room, List<String> jids) {
    this
        ._connection
        .muc
        .multipleInvites(room, jids, 'Je vous invite à rejoindre mon groupe');
  }

  queryOccupants(String name) {
    name = name.replaceAll(new RegExp(' '), '_');
    name = name.replaceAll(new RegExp('[éèêë]'), 'e');
    name = name.replaceAll(new RegExp('[ùûü]'), 'u');
    name = name.replaceAll(new RegExp('[îï]'), 'i');
    name = name.replaceAll(new RegExp('[àâä]'), 'a');
    name = name.toLowerCase();
    if (name != null && name.isNotEmpty) {
      String room = this._formatToJid(name, this._mucService);
      this._connection.muc.queryOccupants(room, (iq) {
        print(iq);
      }, (err) {
        print(err);
      });
    }
  }

  setTopic(String room, String topic) {
    this._connection.muc.setTopic(room, topic);
  }

  getUserGroup([String jid, node = 'http://jabber.org/protocol/muc#rooms']) {
    jid = jid ?? this.jid;
    this._connection.disco.items(
        jid,
        node,
        (result) => {
              // console.log(result)
            },
        (error) => {
              // console.log(error)
            });
  }

  createConfiguredRoom(String name, List members) {
    name = name ?? '';
    name = name.replaceAll(new RegExp(' '), '_');
    name = name.replaceAll(new RegExp('[éèêë]'), 'e');
    name = name.replaceAll(new RegExp('[ùûü]'), 'u');
    name = name.replaceAll(new RegExp('[îï]'), 'i');
    name = name.replaceAll(new RegExp('[àâä]'), 'a');
    name = name.toLowerCase();
    String room = this._formatToJid(name, this._mucService);
    Map<String, String> config = {
      "muc#roomconfig_roomdesc": name + ' group',
      "muc#roomconfig_whois": "anyone",
      "muc#roomconfig_roomname": name,
      "muc#roomconfig_persistentroom": "1"
    };

    if (!this._connection.connected) return;
    this._connection.muc.createConfiguredRoom(room, config, (iqSuccess) {
      // console.log(room, ' crée avec success');
      // console.log(iqSuccess);
      if (members != null && members.length > 0) {
        members.forEach((member) {
          this.modifyGroupAffiliation(room, member);
        });
      }
      this.getConfigOfGroup(room);
      this.joinGroup(room, Strophe.getNodeFromJid(this.jid));
      this.setTopic(room, name);
    }, (iqError) {
      // console.log(room, ' non crée');
      // console.log(iqError);
    });
  }

  leaveGroup(String room, String nick) {
    this._connection.muc.leave(room, nick, () => {});
  }

  getConfigOfGroup(String room) {
    StanzaBuilder iq = Strophe.Builder('iq', attrs: {
      'from': this.jid,
      'id': this._connection.getUniqueId(),
      'to': room,
      'type': 'get'
    });
    iq.c('query', {'xmlns': 'http://jabber.org/protocol/muc#owner'});
    this._connection.sendIQ(
        iq.tree(),
        (iq) => {
              // console.log(iq);
            },
        (iqError) => {
              // console.log(iqError);
            });
  }

  destroyGroup(String room, [String reason = 'Envie de détruire le groupe']) {
    StanzaBuilder iq = Strophe.Builder('iq', attrs: {
      'from': this.jid,
      'id': this._connection.getUniqueId(),
      'to': room,
      'type': 'set'
    });
    iq
        .c('query', {'xmlns': 'http://jabber.org/protocol/muc#owner'})
        .c('destroy')
        .c('reason')
        .t(reason);
    this._connection.sendIQ(
        iq.tree(),
        (iq) => {
              // console.log(iq);
            },
        (iqError) => {
              // console.log(iqError);
            });
  }

  modifyGroupAffiliation(String room, String jid, [String type = 'member']) {
    switch (type) {
      case 'member':
        this._connection.muc.member(
            room,
            jid,
            '',
            (iq) => {
                  //// console.log(iq)
                },
            (iqError) => {
                  //// console.log(iqError);
                });
        return;
      case 'outcast':
        this._connection.muc.ban(
            room,
            jid,
            '',
            (iq) => {
                  // console.log(iq)
                },
            (iqError) => {
                  // console.log(iqError);
                });
        return;
      case 'admin':
        this._connection.muc.admin(
            room,
            jid,
            '',
            (iq) => {
                  // console.log(iq)
                },
            (iqError) => {
                  // console.log(iqError);
                });
        return;
    }
  }

  createBookmarksNode() {
    this._connection.bookmarks.createBookmarksNode((iq) {
      print("$iq");
    }, (err) {
      print(err);
    });
  }

  addOrUpdateBookmark(String roomJid, String alias, String nick,
      [bool autojoin = true]) {
    this._connection.bookmarks.add(roomJid, alias, nick, autojoin, (iq) {
      print("$iq");
    }, (err) {
      print(err);
    });
  }

  deleteBookmark(String roomJid) {
    this._connection.bookmarks.delete(roomJid, (iq) {
      print("deleteBookmark $iq");
    }, (err) {
      print(err);
    });
  }

  getBookmarks() {
    this._connection.bookmarks.get((iq) {
      print("getBookmarks $iq");
    }, (err) {
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
