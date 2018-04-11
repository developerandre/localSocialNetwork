import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:localsocialnetwork/providers/models.dart';
import 'package:localsocialnetwork/providers/store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:localsocialnetwork/pages/chat/chat.page.dart';
import 'package:localsocialnetwork/utils.dart';

class ContactsPage extends StatefulWidget {
  @override
  _ContactsPageState createState() => new _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  GlobalKey<ScaffoldState> _scaffold = new GlobalKey<ScaffoldState>();
  List<AppContact> _contacts = [];
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
                      child: new Text('Account'),
                    ),
                  ],
              onSelected: (int value) {
                if (value == 0) {
                  Navigator.of(context).pushNamed(AppRoutes.account);
                }
              },
            )
          ],
        ),
        body: new StreamBuilder(
          stream: StoreProvider.instance.getContacts(),
          builder:
              (BuildContext context, AsyncSnapshot<List<AppContact>> snapchot) {
            if (snapchot.hasError || snapchot.data == null) {
              return new Center(
                child: new CircularProgressIndicator(),
              );
            }
            _contacts = snapchot.data;
            return new ListView(
              children: _contactsTiles(),
            );
          },
        ),
      );

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((SharedPreferences preferences) {
      String phoneNumber = preferences.getString(AppPreferences.phoneNumber);
      setState(() {
        _title = phoneNumber;
      });
    }).catchError((e) {
      print(e);
    });
  }

  List<Widget> _contactsTiles() {
    List<Widget> tiles = [];
    if (_contacts.length == 0) return [];
    _contacts.forEach((AppContact contact) {
      tiles.add(new Padding(
          padding: new EdgeInsets.only(right: 15.0),
          child: new Divider(indent: 60.0)));
      tiles.add(new Dismissible(
        onDismissed: (DismissDirection direction) {},
        key: new Key(contact.phone),
        child: new Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
          new Container(
            margin: new EdgeInsets.only(
                top: 5.0, bottom: 3.0, left: 8.0, right: 10.0),
            padding: new EdgeInsets.all(2.0),
            height: 50.0,
            width: 50.0,
            decoration: new BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
                border:
                    new Border.all(width: 2.0, color: Colors.blue.shade600)),
            child: new ClipOval(
              child: new Center(
                child: new Text(contact.name != null && contact.name.length > 0
                    ? contact.name[0].toUpperCase()
                    : ''),
              ),
            ),
          ),
          new Expanded(
            child: new Material(
              child: new InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      new MaterialPageRoute(
                          builder: (_) => new ChatPage(
                                title: contact.phone,
                              )));
                },
                child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      new Text(
                        contact.name,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: Theme
                            .of(context)
                            .textTheme
                            .display1
                            .copyWith(fontSize: 19.0),
                      ),
                      new Row(
                        children: <Widget>[
                          new Icon(Icons.done_all, size: 12.0),
                          new Expanded(
                            child: new Text(
                              "qsdfgsqgmljsqmljglmsqjgqmlkdsgsngmlnqsmlgnlkqsblkgbqlksnglkqlkgqgsqfgqsdgsqgsqg",
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      )
                    ]),
              ),
            ),
          ),
          new Container(
              margin: new EdgeInsets.all(5.0),
              child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    new Row(children: <Widget>[
                      new Container(
                        width: 5.0,
                        height: 5.0,
                        margin: new EdgeInsets.symmetric(horizontal: 1.0),
                        decoration: new BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green.shade600),
                      ),
                      new Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: new Stack(children: <Widget>[
                          new Icon(Icons.arrow_drop_down),
                          new Positioned(
                            top: 0.0,
                            right: 0.0,
                            child: new Icon(Icons.brightness_1,
                                size: 8.0, color: Colors.redAccent),
                          )
                        ]),
                      ),
                      new Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: new Text("10:30"),
                      )
                    ]),
                    new Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        new Container(
                          width: 20.0,
                          height: 20.0,
                          margin: new EdgeInsets.symmetric(horizontal: 1.0),
                          child: new Center(
                              child: new Icon(Icons.trending_up, size: 15.0)),
                          decoration: new BoxDecoration(
                              border: new Border.all(
                                  width: 2.0, color: Colors.black12),
                              shape: BoxShape.circle,
                              color: Colors.transparent),
                        ),
                        new Container(
                          width: 15.0,
                          height: 15.0,
                          margin: new EdgeInsets.symmetric(horizontal: 1.0),
                          child: new Center(
                              child: new Icon(Icons.volume_off, size: 15.0)),
                          decoration: new BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.transparent),
                        ),
                        new Container(
                          width: 25.0,
                          height: 25.0,
                          margin: new EdgeInsets.symmetric(horizontal: 1.0),
                          child: new Center(child: new Text("2")),
                          decoration: new BoxDecoration(
                              shape: BoxShape.circle, color: Colors.lightBlue),
                        )
                      ],
                    ),
                  ]))
        ]),
      ));
    });
    tiles.removeAt(0);
    return tiles;
  }
}
