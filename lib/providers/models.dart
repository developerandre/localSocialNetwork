class AppContact {
  String phone;
  String firstName;
  String lastName;
  String email;
  bool silent;
  bool order;
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
}

class ContactVCard {
  String birthDay;
  String title;
  String desc;
  String siteWeb;
  List<ContactAdress> adresses;
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
