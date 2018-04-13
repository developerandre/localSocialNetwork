import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:localsocialnetwork/pages/chat/chat-message.dart';
import 'package:localsocialnetwork/pages/serachbar.dart';
import 'package:localsocialnetwork/providers/models.dart';
import 'package:localsocialnetwork/providers/xmpp.dart';
import 'package:emoji/emoji.dart';
import 'package:emoji/data/emoji.dart';

class ChatPage extends StatefulWidget {
  final AppContact contact;

  ChatPage({@required this.contact}) {
    print(contact.jid);
  }

  @override
  _ChatPageState createState() => new _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  GlobalKey<ScaffoldState> _scaffold = new GlobalKey<ScaffoldState>();

  String _message = '';

  IconData _emojiIcon = Icons.insert_emoticon;

  TextEditingController _messageController = new TextEditingController();

  String _search = '';

  bool _isSearch = false;

  List<int> _contactOptionsPinned = [];

  bool _contactsOptions = false;

  @override
  Widget build(BuildContext context) => new Scaffold(
      key: _scaffold,
      appBar: _buildAppBar(),
      body: new Column(
        children: [
          new Expanded(
              child: new ListView.builder(
            itemCount: 5,
            itemBuilder: (_, int index) => _messageView(index),
          )),
          new Divider(height: 1.0),
          new Container(
            decoration: new BoxDecoration(color: Theme.of(context).cardColor),
            child: new Row(
              children: [
                new IconButton(
                  icon: new Icon(_emojiIcon),
                  onPressed: _buildEmoticons,
                  color: Theme.of(context).primaryColor,
                ),
                new Expanded(
                  child: new TextField(
                    controller: _messageController,
                    onChanged: (String value) {
                      if (value.isNotEmpty &&
                          (value.length == 2 || value.length % 10 == 0)) {
                        XmppProvider
                            .instance()
                            .sendComposing(widget.contact.jid);
                      }
                      setState(() {
                        _message = value;
                      });
                    },
                    decoration: new InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Send a message',
                    ),
                  ),
                ),
                new IconButton(
                  icon: TargetPlatform.android == defaultTargetPlatform
                      ? new Icon(Icons.send)
                      : new Text('Send'),
                  onPressed: _message.isNotEmpty ? _sendMessage : null,
                  color: Theme.of(context).primaryColor,
                )
              ],
            ),
          )
        ],
      ));

  @override
  void initState() {
    super.initState();
  }

  Widget _messageView(int index) {
    AppMessage message = new AppMessage();
    if (index.isEven)
      message.from = 'tonandre@localhost';
    else
      message.from = '1237@localhost';
    message.name = 'Le nom ';
    message.content = 'SQFSQgqs g qjgkqgqkjgqjgqgqg g qgq';
    AnimationController animation = new AnimationController(
        vsync: this, duration: new Duration(milliseconds: 800));
    animation.forward();
    return new ChatMessage(message: message, animation: animation);
  }

  void _sendMessage() {
    if (_message.isEmpty) return;
    XmppProvider.instance().sendMessage(widget.contact.jid, _message);
    setState(() {
      _message = '';
      _messageController.text = '';
    });
  }

  void _buildEmoticons() {
    setState(() {
      _emojiIcon = Icons.keyboard;
    });
    _scaffold.currentState
        .showBottomSheet((BuildContext context) {
          double height = MediaQuery.of(context).size.height;
          return new Container(
            padding: new EdgeInsets.all(10.0),
            color: Colors.grey.shade200,
            height: height * 0.4,
          );
        })
        .closed
        .then((result) {
          setState(() {
            _emojiIcon = Icons.insert_emoticon;
          });
        });
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
          title: new SearchBar(_onSearch, "Rechercher un message ..."),
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
          automaticallyImplyLeading: false,
          title: new Container(
            child: new Row(
              children: <Widget>[
                new Container(
                    margin: new EdgeInsets.all(0.0), child: new BackButton()),
                new InkWell(
                  onTap: () {},
                  child: new Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: new CircleAvatar(
                      backgroundColor: Colors.red,
                      child: new Text(widget.contact.name != null &&
                              widget.contact.name.length > 0
                          ? widget.contact.name[0].toUpperCase()
                          : ''),
                    ),
                  ),
                ),
                new InkWell(
                  onTap: () {},
                  child: new Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _titleHead()),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            new IconButton(
                icon: new Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    this._isSearch = true;
                  });
                }),
            new PopupMenuButton(
                itemBuilder: (_) => [
                      new PopupMenuItem(
                        value: 0,
                        child: new Text('afficher le profil'),
                      ),
                      new PopupMenuItem(
                        value: 0,
                        child: new Text('Bloquer le contact'),
                      ),
                      new PopupMenuItem(
                        value: 0,
                        child: new Text('Effacer la discussion'),
                      )
                    ])
          ]);
    }
    return appBar;
  }
List<Widget> _titleHead(){
   List<Widget> children = [
                        new Flexible(
                            child: new Text(widget.contact.phone,
                                style: new TextStyle(fontSize: 20.0)))
    ];
    if(widget.contact.writing){
                        children.add(new Flexible(
                            child: new Text("Est en train d'ecrire ...",
                                style: new TextStyle(
                                    color: Colors.green[900],
                                    fontSize: 10.0,
                                    fontStyle: FontStyle.italic))));
    }
    return children;
}
  List<Widget> _appBarOptionsActions() {
    List<Widget> actions = [];
    actions.add(
        new IconButton(icon: new Icon(Icons.volume_off), onPressed: () {}));
    actions.add(
        new IconButton(icon: new Icon(Icons.trending_up), onPressed: () {}));
    actions
        .add(new IconButton(icon: new Icon(Icons.archive), onPressed: () {}));

    return actions;
  }

  _onSearch(String search) {
    setState(() {
      _search = search;
    });
  }
}
