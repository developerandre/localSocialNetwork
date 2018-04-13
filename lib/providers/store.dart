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
  List<AppMessage> _messages;
  ConnectivityResult networkStatus;
  StoreProvider._();
  StoreProvider._internal() {
    this._contacts = {};
    this._getContacts();
    this._messages = [];
  }
  List<AppContact> get contacts {
    List<AppContact> list = this._contacts.values.toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  List<AppMessage> get messages {
    return this._messages;
  }

  static StoreProvider get instance {
    if (_instance == null) {
      _instance = new StoreProvider._internal();
    }
    return _instance;
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

  updateContactPresence(String from, String type) {
    from = 'tonandre@localhost';
    String str = '${this._contacts.length} ';
    this._contacts.forEach((String key, value) {
      str += (value.jid ?? '') + '-';
    });
    print(str);
    AppContact contact = this._contacts[Strophe.getBareJidFromJid(from)];
    print("contact $contact");
    if (contact != null) {
      print(type);
      if (type != null && type == 'unavailable') {
        contact.lastSeen = -1;
      } else {
        contact.lastSeen = 0;
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
        this._contacts.addAll({appContact.phone: appContact});
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
    }
  }

  Stream<List<AppContact>> getContacts() {
    this._getContacts();
    contactsStream.add(_sortContacts());
    return contactsStream.stream;
  }

  List<AppContact> _sortContacts() {
    List<AppContact> list = this._contacts.values.toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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
          this._contacts.putIfAbsent(appContact.phone, () {
            return appContact;
          });
        }
      });
      contactsStream.add(_sortContacts());
    }).catchError((e) {
      print('get contacts error $e');
    });
  }
}
