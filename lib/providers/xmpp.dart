import 'dart:async';

import 'package:localsocialnetwork/providers/models.dart';
import 'package:localsocialnetwork/providers/store.dart';
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
import 'package:xml/xml.dart' as xml;

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
  String _host = '192.168.20.192';
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
    if (domain == null || domain.isEmpty) domain = this._domain;
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
        print("is Connect");
        StoreProvider.instance.isConnected = true;
        this.jid = jid;
        this.handleAfterConnect();
        streamController.close();
      } else if (status == Strophe.Status['DISCONNECTED']) {
        StoreProvider.instance.isConnected = false;
        streamController.close();
      }
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
        streamController.close();
      } else if (status == Strophe.Status['NOTACCEPTABLE']) {
        print("Registration form not properly filled out.");
        streamController.close();
      } else if (status == Strophe.Status['REGIFAIL']) {
        print(
            "The Server does not support In-Band Registration $condition $ele");
        streamController.close();
      } else if (status == Strophe.Status['CONNECTED']) {
        StoreProvider.instance.isConnected = true;
        streamController.close();
        print('is connected');
        this.handleAfterConnect();
      } else if (status == Strophe.Status['DISCONNECTED']) {
        StoreProvider.instance.isConnected = false;
        streamController.close();
      }
    });
    return streamController.stream;
  }

  handleAfterConnect() {
    this.sendPresence();
    this.getRoster();
    this.handlePresence();
    this.handlePepMessage();
    this.handleHeadlineMessage();
    this.handleEventsMessage();
    this.handleInviteMessage();
    this.handleMessage();
    this.handleGroupMessage();
    this.handleComposingMessage();
    this.handleNormalMessage();
  }

  void getRoster() {}
  void handlePresence() {
    this._connection.addHandler((presence) {
      return true;
    }, null, 'presence');
  }

  void handleInviteMessage() {
    this._connection.addHandler((xml.XmlElement msg) {
      print(msg);
      String from = msg.getAttribute('from');
      String domain = Strophe.getDomainFromJid(from);
      String sender, room;
      if (domain == this._mucService) {
        room = Strophe.getNodeFromJid(from);
        //is mediated invitation
        List<xml.XmlElement> invites = msg.findAllElements('invite').toList();
        if (invites.length > 0) {
          xml.XmlElement invite = invites[0];
          sender = Strophe.getBareJidFromJid(invite.getAttribute('from'));
        }
        if (room != null && sender != null) {
          ContactNotification notification = new ContactNotification();
          notification.content =
              '$sender vous invite à rejoindre le groupe $room';
          notification.from = sender;
          notification.notificationType = NotificationType.GROUP_INVITATION;
          StoreProvider.instance
              .addNotification(notification, notification.from);
        }
      }
      return true;
    }, Strophe.NS['MUC_USER'], 'message');
  }

  void handleEventsMessage() {
    this._connection.addHandler((xml.XmlElement msg) {
      print(msg);
      return true;
    }, Strophe.NS['PUBSUB_EVENT'], 'message');
  }

  void handleHeadlineMessage() {
    this._connection.addHandler((xml.XmlElement msg) {
      print(msg);
      if (!_namespaceMatch(msg, Strophe.NS['PUBSUB']) &&
          !_namespaceMatch(msg, Strophe.NS['PUBSUB_EVENT'])) {}
      return true;
    }, null, 'message', 'headline');
  }

  void handlePepMessage() {
    this._connection.addHandler((xml.XmlElement msg) {
      print(msg);
      return true;
    }, Strophe.NS['PUBSUB'], 'message', 'headline');
  }

  void handleComposingMessage() {
    this._connection.addHandler((xml.XmlElement msg) {
      print(msg);
      String from = msg.getAttribute('from');
      List<xml.XmlElement> composing =
          msg.findAllElements('composing').toList();
      if (composing.length > 0) {
        StoreProvider.instance
            .setContactInfos(from, ContactField.writing, true);
      }
      return true;
    }, Strophe.NS['CHATSTATES'], 'message', ['chat', 'groupchat']);
  }

  void handleGroupMessage() {
    this._connection.addHandler((xml.XmlElement msg) {
      print(msg);
      return true;
    }, null, 'message', 'groupchat');
  }

  void handleMessage() {
    this._connection.addHandler((xml.XmlElement msg) {
      print(msg);
      return true;
    }, null, 'message', 'chat');
  }

  void handleNormalMessage() {
    this._connection.addHandler((xml.XmlElement msg) {
      print(msg);
      return true;
    }, null, 'message', 'normal');
  }

  sendPresence() {
    if (!this._connection.connected) return;
    _connection.sendPresence(Strophe.$pres().tree());
  }

  getLastActivity(String jid) {
    jid = this._formatToJid(jid);
    this._connection.lastactivity.getLastActivity(jid, (xml.XmlElement iq) {
      List<xml.XmlElement> query = iq.findAllElements('query').toList();
      if (query.length > 0) {
        String seconds = query[0].getAttribute('seconds');
        StoreProvider.instance
            .setContactInfos(jid, ContactField.lastSeen, int.parse(seconds));
      }
    }, (err) {});
  }

  sendComposing(String jid, [String type = 'chat']) {
    if (type == 'chat')
      jid = this._formatToJid(jid);
    else if (type == 'groupchat')
      jid = this._formatToJid(jid, this._mucService);
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
    this
        ._connection
        .admin
        .getRegisteredUsersNum((xml.XmlElement iq) {}, (error) {});
  }

  getOnlineUsersNum() {
    this
        ._connection
        .admin
        .getOnlineUsersNum((xml.XmlElement iq) {}, (error) {});
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
    this
        ._connection
        .pubsub
        .createNode(node, config, (xml.XmlElement result) {});
  }

  getDefaultCanalConfig() {
    this._connection.pubsub.getDefaultNodeConfig((xml.XmlElement iq) {});
  }

  getCanalCanalConfig(String node) {
    this._connection.pubsub.getConfig(node, (xml.XmlElement iq) {});
  }

  discoverCanals() {
    this._connection.pubsub.discoverNodes((xml.XmlElement iq) {}, (iq) {});
  }

  getCanalItems(String node) {
    this._connection.pubsub.items(node, (xml.XmlElement iq) {}, (iq) {});
  }

  publishCanalItems(String node, List<Map<String, dynamic>> items) {
    this._connection.pubsub.publish(node, items, (xml.XmlElement iq) {});
  }

  getSubscriptionsOfUserJid() {
    this._connection.pubsub.getSubscriptions((xml.XmlElement iq) {});
  }

  getCanalAffiliations(String node) {
    this._connection.pubsub.getAffiliations(node, (xml.XmlElement iq) {});
  }

  setCanalAffiliations(String node, String jid, String affiliation) {
    jid = this._formatToJid(jid);
    this._connection.pubsub.setAffiliation(node, jid, affiliation, (iq) {});
  }

  subscribeToCanal(String node) {
    this
        ._connection
        .pubsub
        .subscribe(node, null, (xml.XmlElement evt) {}, (xml.XmlElement iq) {});
  }

  unsubscribeToCanal(String node, String jid) {
    jid = this._formatToJid(jid);
    this
        ._connection
        .pubsub
        .unsubscribe(node, jid, null, (xml.XmlElement iq) {}, (err) {});
  }

  getCanalSubscriptions(String node) {
    this._connection.pubsub.getNodeSubscriptions(node, (xml.XmlElement iq) {});
  }

  deleteCanal(String node) {
    this._connection.pubsub.deleteNode(node, (xml.XmlElement iq) {});
  }

  publishPepItems(String node, List<Map<String, dynamic>> items) {
    this._connection.pep.publish(node, items, (xml.XmlElement iq) {});
  }

  subscribeToPep(String node) {
    this._connection.pep.subscribe(node, (xml.XmlElement iq) {});
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

  getvCard([String jid, Function callback]) {
    jid = this._formatToJid(jid);
    this._connection.vcard.get(
        (xml.XmlElement iq) {
          print("getvCard: $iq");
          StoreProvider.instance.setContactInfos(jid, ContactField.vCard, iq);
          if (callback != null) callback(true);
        },
        jid,
        (iq) {
          print("error of getting vCard");
          if (callback != null) callback(false);
        });
  }

  setvCard(VCardEl ele, [String jid, Function callback]) {
    jid = this._formatToJid(jid);
    this._connection.vcard.set(
        (iq) {
          print(iq);
          if (callback != null) callback(true);
        },
        ele,
        jid,
        (iq) {
          print("error of getting vCard");
          if (callback != null) callback(false);
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

  joinGroup(String name, [String nick]) {
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
    jids = jids.map((String jid) {
      return this._formatToJid(jid);
    }).toList();
    room = this._formatToJid(room, this._mucService);
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

  getGroupAffiliations(String room, [String affiliation = 'member']) {
    room = this._formatToJid(room, this._mucService);
    StanzaBuilder el = Strophe
        .$iq({'type': 'get', 'to': room, 'from': this._connection.jid}).c(
            'query', {'xmlns': 'http://jabber.org/protocol/muc#admin'});
    el.c('item', {'affiliation': affiliation});
    this._connection.sendIQ(el.tree(), (iq) {
      print(iq);
    }, (err) {
      print(err);
    });
  }

  setTopic(String room, String topic) {
    room = this._formatToJid(room, this._mucService);
    this._connection.muc.setTopic(room, topic);
  }

  getUserGroup([String jid, node = 'http://jabber.org/protocol/muc#rooms']) {
    jid = jid ?? this.jid;
    jid = this._formatToJid(jid);
    this._connection.disco.items(jid, node, (result) {
      print('user room $result');
    }, (error) {
      // console.log(error)
    });
  }

  createConfiguredRoom(String name, [List<String> members]) {
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
      "muc#roomconfig_persistentroom": "1",
      "muc#roomconfig_membersonly": "1"
    };

    if (!this._connection.connected) return;
    this._connection.muc.createConfiguredRoom(room, config, (iqSuccess) {
      print('$room crée avec success');
      print(iqSuccess);
      this.addOrUpdateBookmark(room, room);
      if (members != null && members.length > 0) {
        members.forEach((member) {
          this.modifyGroupAffiliation(room, member);
        });
      }
      this.joinGroup(room, Strophe.getNodeFromJid(this.jid));
      this.setTopic(room, name);
    }, (iqError) {
      print('$room non crée');
      print(iqError);
    });
  }

  leaveGroup(String room, String nick) {
    room = this._formatToJid(room, this._mucService);
    this._connection.muc.leave(room, nick, () => {});
  }

  getConfigOfGroup(String room) {
    room = this._formatToJid(room, this._mucService);
    StanzaBuilder iq = Strophe.Builder('iq', attrs: {
      'from': this.jid,
      'id': this._connection.getUniqueId(),
      'to': room,
      'type': 'get'
    });
    iq.c('query', {'xmlns': 'http://jabber.org/protocol/muc#owner'});
    this._connection.sendIQ(iq.tree(), (iq) {
      print(iq.toString());
    }, (iqError) {
      print(iqError);
    });
  }

  destroyGroup(String room, [String reason = 'Envie de détruire le groupe']) {
    room = this._formatToJid(room, this._mucService);
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
    room = this._formatToJid(room, this._mucService);
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

  addOrUpdateBookmark(String roomJid, String alias,
      [String nick, bool autojoin = true]) {
    roomJid = this._formatToJid(roomJid, this._mucService);
    this._connection.bookmarks.add(roomJid, alias, nick, autojoin, (iq) {
      print("addOrUpdateBookmark $iq");
    }, (err) {
      print("addOrUpdateBookmark error $err");
    });
  }

  deleteBookmark(String roomJid) {
    roomJid = this._formatToJid(roomJid, this._mucService);
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
    jid = this._formatToJid(jid);
    this._connection.disco.items(jid, node, (iq) {
      print(iq);
    }, (err) {
      print(err);
    });
  }

  discoveryInfosFor(String jid, [String node]) {
    jid = this._formatToJid(jid);
    this._connection.disco.info(jid, node, (iq) {}, (err) {});
  }

  addDiscoveryItem(String jid, String name, String node, [Function callback]) {
    jid = this._formatToJid(jid);
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

  bool _namespaceMatch(xml.XmlNode elem, String ns) {
    bool nsMatch = false;
    if (ns == null || ns.isEmpty) {
      return true;
    } else {
      Strophe.forEachChild(elem, null, (elem) {
        if (this._getNamespace(elem) == ns) {
          nsMatch = true;
        }
      });
      nsMatch = nsMatch || _getNamespace(elem) == ns;
    }
    return nsMatch;
  }

  String _getNamespace(xml.XmlNode node) {
    xml.XmlElement elem =
        node is xml.XmlDocument ? node.rootElement : node as xml.XmlElement;
    String elNamespace = elem.getAttribute("name") ?? '';
    return elNamespace;
  }
}
