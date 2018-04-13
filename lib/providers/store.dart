import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:localsocialnetwork/providers/models.dart';
import 'package:localsocialnetwork/strophe/core.dart';
import 'package:localsocialnetwork/strophe/plugins/roster.dart';

class StoreProvider {
  static StoreProvider _instance;

  Map<String, AppContact> _contacts;

  StreamController<List<AppContact>> contactsStream =
      new StreamController<List<AppContact>>();
  bool isConnected = false;
  Map<String, List<AppMessage>> _messages;
  ConnectivityResult networkStatus;
  StoreProvider._();
  StoreProvider._internal() {
    this._contacts = {};
    this._getContacts();
    this._messages = {};
  }
  List<AppContact> get contacts {
    return this._sortContacts();
  }

  List<AppMessage> messages(String key) {
    return this._messages[key] ?? [];
  }

  static StoreProvider get instance {
    if (_instance == null) {
      _instance = new StoreProvider._internal();
    }
    return _instance;
  }

  String unread(List<AppMessage> msgs) {
    if (msgs == null || msgs.length == 0) return '';
    Iterable<AppMessage> where = msgs.where((AppMessage msg) {
      return msg.unread;
    }).toList();
    return where.length.toString();
  }

  addMessages(String myJid, AppMessage message) {
    if (message == null || myJid == null) return;
    String jid = message.from == myJid ? message.to : message.from;
    if (this._messages[jid] == null) {
      this._messages[jid] = [];
    }
    int indexId = this._messages[jid].indexWhere((AppMessage msg) {
      return msg.id == message.id;
    });
    if (indexId == -1)
      this._messages[jid].add(message);
    else
      this._messages[jid].replaceRange(indexId, indexId + 1, [message]);
    contactsStream.add(this._sortContacts());
  }

  addNotification(ContactNotification notification, String from) {
    AppContact contact = this._contacts[Strophe.getBareJidFromJid(from)];
    if (contact != null) {
      contact.notifications.add(notification);
    } else {
      contact = new AppContact();
      contact.phone = Strophe.getNodeFromJid(from);
      contact.notifications.add(notification);
    }
    this._contacts[Strophe.getBareJidFromJid(from)] = contact;
  }

  updateContactPresence(String from, String type, [String stamp]) {
    AppContact contact = this._contacts[Strophe.getBareJidFromJid(from)];
    if (contact != null) {
      if (type != null && type == 'unavailable') {
        contact.lastSeen = stamp != null && stamp.isNotEmpty
            ? int.parse(DateTime.parse(stamp).millisecondsSinceEpoch.toString())
            : -1;
      } else {
        contact.lastSeen = stamp != null && stamp.isNotEmpty
            ? int.parse(DateTime.parse(stamp).millisecondsSinceEpoch.toString())
            : 0;
      }
      this._contacts[Strophe.getBareJidFromJid(from)] = contact;
      this.contactsStream.add(this.contacts);
    }
  }

  deleteNotification(String from) {
    try {
      this._contacts.remove(from);
    } catch (e) {}
  }

  mergeContacts(List<RosterItem> items) {
    items.forEach((RosterItem item) {
      AppContact mcontact = this._contacts[Strophe.getBareJidFromJid(item.jid)];
      if (mcontact == null) {
        AppContact appContact = new AppContact();
        appContact.phone = Strophe.getBareJidFromJid(item.jid);
        appContact.name = item.name;
        appContact.subscription = item.subscription;
        appContact.ask = item.ask;
        appContact.typeContact = ContactType.INDIVIDU;
        this._contacts.addAll({appContact.jid: appContact});
        contactsStream.add(_sortContacts());
      }
    });
  }

  setContactInfos(String jid, ContactField field, dynamic value) {
    AppContact mcontact = this._contacts[Strophe.getBareJidFromJid(jid)];
    if (mcontact != null) {
      if (field == ContactField.activity) {
        mcontact.activity = value;
      } else if (field == ContactField.order) {
        mcontact.order = 1;
      } else if (field == ContactField.lastSeen) {
        mcontact.lastSeen = value;
      } else if (field == ContactField.writing) {
        mcontact.writing = value;
      } else if (field == ContactField.location) {
        mcontact.location = value;
      } else if (field == ContactField.mood) {
        mcontact.mood = value;
      } else if (field == ContactField.silent) {
        mcontact.silent = value;
      } else if (field == ContactField.profilUrl) {
        mcontact.profilUrl = value;
      } else if (field == ContactField.isBlocked) {
        mcontact.isBlocked = value;
      } else if (field == ContactField.vCard) {
        mcontact.vCard = new ContactVCard.fromIq(value);
      }
      this._contacts[Strophe.getBareJidFromJid(jid)] = mcontact;
      this.contactsStream.add(this.contacts);
    }
  }

  Stream<List<AppContact>> getContacts() {
    this._getContacts();
    contactsStream.add(_sortContacts());
    return contactsStream.stream;
  }

  List<AppContact> _sortContacts() {
    List<AppContact> list = this._contacts.values.toList();
    list.sort((AppContact a, AppContact b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  _getContacts() {
    // if (true == true) return;
    AppContact appContact;
    ContactsService.getContacts().then((Iterable<Contact> mcontacts) {
      mcontacts.toList().forEach((Contact mcontact) {
        List<Item> listPhones = mcontact.phones.toList();
        if (listPhones.length > 0 &&
            listPhones[0].value.trim().length > 6 &&
            !listPhones[0].value.trim().startsWith(new RegExp(r"[*#]"))) {
          appContact = new AppContact();
          appContact.phone = listPhones[0].value;
          appContact.name = (mcontact.displayName ?? '') ??
              ((mcontact.givenName ?? '') +
                      ' ' +
                      (mcontact?.middleName ?? '') +
                      (mcontact.middleName != null &&
                              mcontact.middleName.isNotEmpty
                          ? ' '
                          : '') +
                      (mcontact.familyName ?? ''))
                  .trim();
          appContact.typeContact = ContactType.INDIVIDU;
          this._contacts.putIfAbsent(appContact.jid, () {
            return appContact;
          });
        }
      });
      contactsStream.add(_sortContacts());
    }).catchError((e) {});
  }
}
