import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';


class ContactsPage extends StatefulWidget {

    @override
    State<ContactsPage> createState() => new ContactsPageState();
}

class ContactsPageState extends State<ContactsPage> {
    GlobalKey<ScaffoldState> _scaffold = new GlobalKey<ScaffoldState>();
    Iterable<Contact> _contacts = [];

    @override
    Widget build(BuildContext context) => new Scaffold(
        key: _scaffold,
        appBar: new AppBar(
            title: new Text('12345678'),
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
    }

    List<ListTile> _contactsTiles() {
        List<ListTile> tiles = [];

        _contacts.forEach((Contact contact) {
            tiles.add(new ListTile(
                title: new Text(contact.displayName),
                subtitle: contact.phones.toList().isEmpty ? null : new Text(contact.phones.toList()[0].value),
                onTap: () {
                    print(contact);
                },
            ));
        });

        return tiles;
    }
}
