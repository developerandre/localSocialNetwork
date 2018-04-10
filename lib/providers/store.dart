import 'package:connectivity/connectivity.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:localsocialnetwork/providers/models.dart';
import 'package:localsocialnetwork/strophe/core.dart';

class StoreProvider {
  static StoreProvider _instance;

  List<AppContact> _contacts;
  bool isConnected = false;
  List<AppMessage> _messages;
  ConnectivityResult networkStatus;
  StoreProvider._();
  StoreProvider._internal() {
    this._contacts = [];
    //this._getContacts();
    this._messages = [];
  }
  List<AppContact> get contacts {
    return this._contacts;
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
    this._contacts.map((AppContact mcontact) {
      if (Strophe.getBareJidFromJid(from) == mcontact.jid)
        mcontact.notifications.add(notification);
      return mcontact;
    });
  }

  deleteNotification(String from, int index) {
    try {
      this._contacts.removeAt(index);
    } catch (e) {}
  }

  setContactInfos(String jid, ContactField field, dynamic value) {
    this._contacts.map((AppContact mcontact) {
      if (mcontact.jid == Strophe.getBareJidFromJid(jid)) {
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
      }
      return mcontact;
    });
  }

  _getContacts() {
    ContactsService.getContacts().then((Iterable<Contact> mcontacts) {
      _contacts = mcontacts.toList().map((Contact mcontact) {
        AppContact appContact = new AppContact();
        appContact.name = (mcontact.familyName +
                '' +
                mcontact.givenName +
                '' +
                mcontact.middleName) ??
            mcontact.displayName;
        appContact.typeContact = ContactType.INDIVIDU;
        return appContact;
      }).toList();
    }).catchError((e) {
      print('get contacts error $e');
    });
  }
}
