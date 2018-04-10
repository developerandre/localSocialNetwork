import 'package:localsocialnetwork/strophe/core.dart';
import 'package:xml/xml/nodes/element.dart';

class AppMessage {}

class AppContact {
  String _jid;
  String phone;
  String name;
  String firstName;
  String lastName;
  bool silent;
  int order;
  bool writing;
  String profilUrl;
  ContactType typeContact;
  int lastSeen;
  bool isBlocked;
  String mood;
  String location;
  String activity;
  ContactVCard vCard;
  List<ContactNotification> notifications;
  AppContact() {
    this.isBlocked = false;
    this.mood = '';
    this.location = '';
    this.activity = "";
    this.silent = false;
    this.order = 0;
    this.writing = false;
  }
  String get jid {
    return this._jid;
  }

  set jid(String newJid) {
    if (newJid != null && newJid.isNotEmpty)
      this._jid = Strophe.getBareJidFromJid(newJid);
  }
}

class ContactVCard {
  String birthDay = '';
  String title = '';
  String desc = '';
  String email = '';
  String siteWeb = '';
  List<ContactAdress> adresses = [];
  ContactVCard.fromIq(XmlElement iq) {
    List<XmlElement> list = iq.findAllElements('EMAIL').toList();
    if (list.length > 0) this.email = list[0].text;
    List<XmlElement> list2 = iq.findAllElements('DESC').toList();
    if (list2.length > 0) this.desc = list2[0].text;
    List<XmlElement> list3 = iq.findAllElements('URL').toList();
    if (list3.length > 0) this.siteWeb = list3[0].text;
    List<XmlElement> list4 = iq.findAllElements('BDAY').toList();
    if (list4.length > 0) this.birthDay = list4[0].text;
    List<XmlElement> list5 = iq.findAllElements('TITLE').toList();
    if (list5.length > 0) this.title = list5[0].text;
    List<XmlElement> list6 = iq.findAllElements('ADR').toList();
    if (list6.length > 0) {
      this.adresses = [];
      list6.forEach((XmlElement addr) {
        ContactAdress contactAdress = new ContactAdress();
        List<XmlElement> ctrys = addr.findElements('CTRY').toList();
        if (ctrys.length > 0) contactAdress.country = ctrys[0].text;
        List<XmlElement> regions = addr.findElements('REGION').toList();
        if (regions.length > 0) contactAdress.region = regions[0].text;
        List<XmlElement> localities = addr.findElements('LOCALITY').toList();
        if (localities.length > 0) contactAdress.locality = localities[0].text;
        List<XmlElement> streets = addr.findElements('STREET').toList();
        if (streets.length > 0) contactAdress.street = streets[0].text;
        this.adresses.add(contactAdress);
      });
    }
  }
}

class ContactAdress {
  String country;
  String region;
  String locality;
  String street;
  String voiceNum;
  String faxNum;
  String msgNum;
}

class ContactNotification {
  String from;
  String content;
  NotificationType notificationType;
}

enum NotificationType { GROUP_INVITATION }
enum ContactType { INDIVIDU, GROUP, CANAL }
enum ContactField {
  phone,
  name,
  firstName,
  lastName,
  silent,
  order,
  writing,
  profilUrl,
  typeContact,
  lastSeen,
  isBlocked,
  mood,
  location,
  activity,
  vCard
}
