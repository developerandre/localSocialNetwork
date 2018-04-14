import 'package:flutter/material.dart';
import 'package:localsocialnetwork/pages/groupes/create-groupe.dart';
import 'package:localsocialnetwork/pages/profil/profil.dart';
import 'package:localsocialnetwork/pages/serachbar.dart';
import 'package:localsocialnetwork/providers/models.dart';
import 'package:localsocialnetwork/providers/store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:localsocialnetwork/pages/chat/chat.page.dart';
import 'package:localsocialnetwork/utils.dart';
import '../chain/create_chain.dialog.page.dart';

class ContactsPage extends StatefulWidget {
  @override
  _ContactsPageState createState() => new _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  GlobalKey<ScaffoldState> _scaffold = new GlobalKey<ScaffoldState>();
  List<AppContact> _contacts = [];
  String _title = 'Local social Network';

  bool _isSearch = false;

  String _search = '';

  bool _contactsOptions = false;

  List<int> _contactOptionsPinned = [];

  @override
  Widget build(BuildContext context) => new Scaffold(
        key: _scaffold,
        appBar: _buildAppBar(),
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
    }).catchError((e) {});
  }

  _onSearch(String search) {
    setState(() {
      _search = search;
    });
  }

  List<Widget> _contactsTiles() {
    List<Widget> tiles = [];
    if (_contacts.length == 0) return [];
    AppContact contact;
    for (int i = 0, len = _contacts.length; i < len; i++) {
      contact = _contacts[i];
      tiles.add(new SizedBox(
          height: 0.5,
          child: new Container(
              margin: new EdgeInsets.only(left: 60.0, right: 15.0),
              color: _contactOptionsPinned.contains(i)
                  ? Colors.black26.withOpacity(0.3)
                  : Colors.black12.withOpacity(0.1))));
      tiles.add(
        new Dismissible(
          key: new Key(i.toString()),
          onDismissed: (DismissDirection direction) {
            //if (i - 1 >= 0) _contacts.removeAt(i - 1);
            //_contacts.removeAt(i);
            _scaffold.currentState.showSnackBar(
                new SnackBar(content: new Text("Discussion archivée")));
          },
          background: new Container(
            color: Colors.green,
            child: new ListTile(
              leading: new Icon(Icons.archive),
            ),
          ),
          secondaryBackground: new Container(
            color: Colors.green,
            child: new ListTile(
              trailing: new Icon(Icons.archive),
            ),
          ),
          child: new Container(
            padding: new EdgeInsets.symmetric(vertical: 5.0),
            color: _contactOptionsPinned.contains(i)
                ? Colors.black12
                : Colors.transparent,
            child: new InkWell(
              onLongPress: () {
                setState(() {
                  if (_contactOptionsPinned.contains(i))
                    _contactOptionsPinned.remove(i);
                  else
                    _contactOptionsPinned.add(i);
                  if (_contactOptionsPinned.length <= 0)
                    _contactsOptions = false;
                  else
                    _contactsOptions = true;
                });
              },
              child: new Row(mainAxisSize: MainAxisSize.max, children: <Widget>[
                new Container(
                  margin: new EdgeInsets.only(
                      top: 5.0, bottom: 3.0, left: 8.0, right: 10.0),
                  padding: new EdgeInsets.all(2.0),
                  height: 50.0,
                  width: 50.0,
                  decoration: new BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                      border: new Border.all(
                          width: _contactOptionsPinned.contains(i) ? 4.0 : 2.0,
                          color: Colors.blue.shade600)),
                  child: new Stack(
                    children: _buildAvatar(contact, i),
                  ),
                ),
                new Expanded(
                  child: new Material(
                    color: Colors.transparent,
                    child: new InkWell(
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      onTap: () {
                        setState(() {
                          _contactOptionsPinned = [];
                          _contactsOptions = false;
                        });
                        Navigator.push(
                            context,
                            new MaterialPageRoute(
                                builder: (_) => new ChatPage(
                                      contact: contact,
                                    )));
                      },
                      child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildCentral(contact)),
                    ),
                  ),
                ),
                new Container(
                    margin: new EdgeInsets.all(5.0),
                    child: new Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          new Row(children: _headOptions(contact)),
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: _footOptions(contact),
                          ),
                        ]))
              ]),
            ),
          ),
        ),
      );
    }
    return tiles;
  }

  List<Widget> _headOptions(AppContact contact) {
    List<Widget> options = [];
    List<AppMessage> messages = StoreProvider.instance.messages(contact.jid);
    if (messages.length > 0) {
      DateTime dateTime =
          new DateTime.fromMillisecondsSinceEpoch(messages.last.date);
      String time =
          '${dateTime.hour.toString().length == 1?"0"+dateTime.hour.toString():dateTime.hour}';
      time +=
          ':${dateTime.minute.toString().length == 1?"0"+dateTime.minute.toString():dateTime.minute}';
      Duration difference = new DateTime.now().difference(dateTime);
      if (difference.inDays == 1) {
        time = 'Hier';
      }
      if (difference.inDays > 1) {
        time =
            '${dateTime.day.toString().length == 1?"0"+dateTime.day.toString():dateTime.day}';
        time +=
            '/${dateTime.month.toString().length == 1?"0"+dateTime.month.toString():dateTime.month}';
        time +=
            '/${dateTime.year.toString().length == 1?"0"+dateTime.year.toString():dateTime.year}';
      }
      options.add(new Padding(
        padding: const EdgeInsets.all(5.0),
        child: new Text(time),
      ));
    }
    if (contact.notifications.length > 0) {
      options.insert(
          0,
          new Padding(
            padding: const EdgeInsets.all(2.0),
            child: new Stack(children: <Widget>[
              new Icon(Icons.arrow_drop_down),
              new Positioned(
                  top: 0.0,
                  right: 0.0,
                  child: new Icon(Icons.brightness_1,
                      size: 8.0, color: Colors.redAccent))
            ]),
          ));
    }
    if (contact.lastSeen != null && contact.lastSeen == 0) {
      options.insert(
          0,
          new Container(
            width: 8.0,
            height: 8.0,
            margin: new EdgeInsets.only(
                left: 1.0, right: options.length == 0 ? 8.0 : 1.0),
            decoration: new BoxDecoration(
                shape: BoxShape.circle, color: Colors.green.shade600),
          ));
    }
    return options;
  }

  List<Widget> _buildCentral(AppContact contact) {
    List<Widget> children = [
      new Text(
        contact.name,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: Theme.of(context).textTheme.display1.copyWith(fontSize: 19.0),
      )
    ];
    List<AppMessage> messages = StoreProvider.instance.messages(contact.jid);
    String content = '';
    if (messages.length > 0) {
      content = messages.last.content;
    } else {
      content = 'Je suis disponible sur local social network';
    }
    Row row = new Row(
      children: <Widget>[
        new Expanded(
          child: new Text(
            content,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            maxLines: 2,
          ),
        ),
      ],
    );
    if (messages.length > 0) {
      IconData icon;
      Color color = Colors.black;
      if (messages.last.status == SentStatus.NO_DELIVERED)
        icon = Icons.crop_square;
      else if (messages.last.status == SentStatus.RECEIVED)
        icon = Icons.done;
      else if (messages.last.status == SentStatus.SENT)
        icon = Icons.done_all;
      else if (messages.last.status == SentStatus.SEEN) {
        icon = Icons.done_all;
        color = Colors.greenAccent;
      }
      row.children.insert(0, new Icon(icon, size: 12.0, color: color));
    }
    children.add(row);
    if (contact.writing) {
      children.add(new Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: new Text(
          "Est en train d'ecrire...",
          overflow: TextOverflow.ellipsis,
          style:
              new TextStyle(color: Colors.green, fontStyle: FontStyle.italic),
        ),
      ));
    }
    return children;
  }

  List<Widget> _footOptions(AppContact contact) {
    List<Widget> options = [];
    List<AppMessage> messages = StoreProvider.instance.messages(contact.jid);
    String unread = StoreProvider.instance.unread(messages);
    if (messages.length > 0 && unread.isNotEmpty && unread != '0') {
      options.add(new Container(
        width: 25.0,
        height: 25.0,
        margin: new EdgeInsets.symmetric(horizontal: 1.0),
        child: new Center(child: new Text(unread)),
        decoration:
            new BoxDecoration(shape: BoxShape.circle, color: Colors.lightBlue),
      ));
    }
    if (contact.silent) {
      options.insert(
          0,
          new Container(
            width: 15.0,
            height: 15.0,
            margin: new EdgeInsets.symmetric(horizontal: 1.0),
            child: new Center(child: new Icon(Icons.volume_off, size: 15.0)),
            decoration: new BoxDecoration(
                shape: BoxShape.circle, color: Colors.transparent),
          ));
    }
    if (contact.order > 0) {
      options.insert(
          0,
          new Container(
            width: 20.0,
            height: 20.0,
            margin: new EdgeInsets.symmetric(horizontal: 1.0),
            child: new Center(child: new Icon(Icons.trending_up, size: 15.0)),
            decoration: new BoxDecoration(
                border: new Border.all(width: 2.0, color: Colors.black12),
                shape: BoxShape.circle,
                color: Colors.transparent),
          ));
    }
    return options;
  }

  List<Widget> _appBarActions() {
    List<Widget> actions = [];
    actions.add(new IconButton(
        icon: new Icon(Icons.search),
        onPressed: () {
          setState(() {
            this._isSearch = true;
          });
        }));
    actions.add(new PopupMenuButton(
      itemBuilder: (_) => [
            // new PopupMenuItem(
            //   value: AppBarAction.PROFIL,
            //   child: new Text('Votre profil'),
            // ),
            new PopupMenuItem(
              value: AppBarAction.CREATE_GROUP,
              child: new Text('Create a group'),
            ),
            new PopupMenuItem(
              value: AppBarAction.CREATE_PAGE,
              child: new Text('Create a chain'),
            ),
            new PopupMenuItem(
              value: AppBarAction.ACCOUNT,
              child: new Text('Account'),
            )
          ],
      onSelected: (AppBarAction value) {
        if (value == AppBarAction.ACCOUNT) {
          Navigator.of(context).pushNamed(AppRoutes.account);
        } else if (value == AppBarAction.CREATE_GROUP) {
          Navigator.of(context).push(new MaterialPageRoute(
              fullscreenDialog: true,
              builder: (BuildContext context) {
                return new CreateGroup();
              }));
        } else if (value == AppBarAction.CREATE_PAGE) {
          Navigator.of(context).push(new MaterialPageRoute(
              fullscreenDialog: true,
              builder: (BuildContext context) {
                return new CreateChainDialog();
              }));
        } else if (value == AppBarAction.PROFIL) {
          Navigator.of(context).push(new MaterialPageRoute(
              fullscreenDialog: true,
              builder: (BuildContext context) {
                return new Profil();
              }));
        }
      },
    ));
    return actions;
  }

  AppBar _buildAppBar() {
    AppBar appBar;
    if (_contactsOptions) {
      appBar = new AppBar(
        leading: new IconButton(
            icon: new Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _contactsOptions = false;
                _contactOptionsPinned = [];
              });
            }),
        title: new Text(_contactOptionsPinned.length.toString()),
        actions: _appBarOptionsActions(),
      );
    } else if (_isSearch) {
      appBar = new AppBar(
          backgroundColor: Colors.black12,
          leading: new IconButton(
              icon: new Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _isSearch = false;
                });
              }),
          title: new SearchBar(_onSearch, "Rechercher ..."),
          elevation: 12.0,
          actions: <Widget>[
            new IconButton(
              padding: new EdgeInsets.all(0.0),
              tooltip: "Effacer la recherche",
              iconSize: 20.0,
              icon: new Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _search = '';
                });
              },
            )
          ]);
    } else {
      appBar = new AppBar(
        title: new Text(_title),
        actions: _appBarActions(),
      );
    }
    return appBar;
  }

  List<Widget> _appBarOptionsActions() {
    List<Widget> actions = [];
    actions.add(
        new IconButton(icon: new Icon(Icons.volume_off), onPressed: () {}));
    actions.add(
        new IconButton(icon: new Icon(Icons.trending_up), onPressed: () {}));
    actions
        .add(new IconButton(icon: new Icon(Icons.archive), onPressed: () {}));
    actions.add(new PopupMenuButton(
        itemBuilder: (_) => [
              new PopupMenuItem(
                value: AppBarAction.PROFIL,
                child: new Text('Voir le contact'),
              )
            ]));
    return actions;
  }

  List<Widget> _buildAvatar(AppContact contact, int i) {
    List<Widget> children = [
      new ClipOval(
        child: new InkWell(
          onTap: _onAvatarTapped,
          child: new Center(
            child: new Text(
                contact.name != null && contact.name.length > 0
                    ? contact.name[0].toUpperCase()
                    : '',
                style: new TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      )
    ];

    if (_contactOptionsPinned.contains(i)) {
      children.add(new Center(
          child: new IconButton(
              onPressed: _onAvatarTapped,
              icon: new Icon(Icons.check, color: Colors.black))));
    }

    return children;
  }

  void _onAvatarTapped() {
    setState(() {
      _contactOptionsPinned = [];
      _contactsOptions = false;
    });
    Navigator.push(
        context, new MaterialPageRoute(builder: (_) => new Profil()));
  }
}

enum AppBarAction { ACCOUNT, CREATE_GROUP, CREATE_PAGE, SETTINGS, PROFIL, HELP }
