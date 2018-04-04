import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:localsocialnetwork/pages/chat/chat.page.dart';


class ContactsPage extends StatefulWidget {
    @override
    ContactsPageState createState() => new ContactsPageState();
}

class ContactsPageState extends State<ContactsPage> {
    GlobalKey<ScaffoldState> _scaffold = new GlobalKey<ScaffoldState>();
    Iterable<Contact> _contacts = [];
    String _title = '';

    @override
    Widget build(BuildContext context) => new Scaffold(
        key: _scaffold,
        appBar: new AppBar(
            title: new Text(_title),
            actions: [
                new PopupMenuButton(
                    itemBuilder: (_) => [
                        new PopupMenuItem(
                            value: 0,
                            child: new Text('Settings'),
                        )
                    ],
                    onSelected: (int value) {
                        print(value);
                    },
                )
            ],
        ),
        body: new ListView(
            children: ListTile.divideTiles(
                context: context,
                tiles: _contactsTiles()
            ).toList(),
        ),
    );

    @override
    void initState() {
        super.initState();
        ContactsService.getContacts()
        .then((Iterable<Contact> contacts) {
            setState(() {
                _contacts = contacts;
            });
        })
        .catchError((e) {
            print(e);
        });

        SharedPreferences.getInstance()
        .then((SharedPreferences preferences) {
            String phoneNumber = preferences.getString('phoneNumber');

            if (phoneNumber == null) {
                // Navigator.of(context).pus
            }
            else {
                setState(() {
                    _title = phoneNumber;
                });
            }
        })
        .catchError((e) {
            print(e);
        });
    }

    List<ListTile> _contactsTiles() {
        List<ListTile> tiles = [];

        _contacts.forEach((Contact contact) {
            tiles.add(new ListTile(
                leading: new CircleAvatar(
                    child: new Text(contact.displayName[0]),
                ),
                title: new Text(contact.displayName),
                subtitle: contact.phones.toList().isEmpty ? null : new Text(contact.phones.toList()[0].value),
                onTap: () {
                    Navigator.push(context, new MaterialPageRoute(
                        builder: (_) => new ChatPage(title: contact.displayName,)
                    ));
                },
            ));
        });

        return tiles;
    }
}
