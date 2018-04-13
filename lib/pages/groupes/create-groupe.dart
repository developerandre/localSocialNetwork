import 'package:flutter/material.dart';
import '../../utils.dart';


class CreateGroup extends StatefulWidget {
    @override
    _CreateGroupState createState() => new _CreateGroupState();
}

class _Member {
    bool selected = false;
    dynamic contact;

    _Member({this.selected: false, this.contact});
}

class _CreateGroupState extends State<CreateGroup> {
    List<_Member> _members = [];
    String _groupName;
    GlobalKey<ScaffoldState> _scaffold = new GlobalKey();
    GlobalKey<FormState> _form = new GlobalKey();

    @override
    Widget build(BuildContext context) {
        return new Scaffold(
            key: _scaffold,
            appBar: new AppBar(
                title: new Text("Creating a group"),
                actions: [
                    new IconButton(
                        icon: new Icon(Icons.check),
                        onPressed: () {
                            if (_geteSelectedContacts().length < 2) {
                                _scaffold.currentState.showSnackBar(new SnackBar(
                                    content: new Text('Select at least 2 contacts'),
                                ));
                            }
                            else {
                                if (_form.currentState.validate()) {
                                    _form.currentState.save();
                                    print(_groupName);
                                    print(_geteSelectedContacts());
                                }
                            }
                        },
                    )
                ],
            ),
            body: new Column(
                children: [
                    new ListTile(
                        leading: new GestureDetector(
                            child: new CircleAvatar(
                                child: new Text('A'),
                            ),
                            onTap: () {
                                Navigator.pushNamed(context, AppRoutes.avatar);
                            },
                        ),
                        title: new Form(
                            key: _form,
                            child: new TextFormField(
                                decoration: new InputDecoration(
                                    hintText: 'Group name'
                                ),
                                validator: (String value) => value.isEmpty ? 'The group name can not be empty' : null,
                                onSaved: (String value) {
                                    _groupName = value;
                                },
                            ),
                        ),
                    ),
                    new MergeSemantics(
                        child: new Container(
                            height: 30.0,
                            padding: const EdgeInsetsDirectional.only(start: 16.0),
                            alignment: AlignmentDirectional.centerStart,
                            child: new SafeArea(
                                top: false,
                                bottom: false,
                                child: new Semantics(
                                    header: true,
                                    child: new Text('Members', 
                                        style: Theme.of(context).textTheme.body2.copyWith(color: Theme.of(context).accentColor),
                                    ),
                                ),
                            ),
                        ),
                    ),
                    new Expanded(
                        child: new ListView(
                            children: ListTile.divideTiles(
                                context: context,
                                tiles: _contactsTiles()
                            ).toList()
                        ),
                    )
                ],
            ),
        );
    }

    List<CheckboxListTile> _contactsTiles() {
        List<CheckboxListTile> tiles = [];

        _members.asMap().forEach((int index, _Member member) {
            tiles.add(new CheckboxListTile(
                title: new Text('data'),
                value: member.selected,
                onChanged: (bool checked) {
                    setState(() {
                        member.selected = checked;
                    });
                },
                secondary: new CircleAvatar(
                    child: new Text('W'),
                ),
                subtitle: new Text('+456353'),
            ));
        });

        return tiles;
    }

    @override
    void initState() {
        super.initState();
        _members.add(new _Member());
        _members.add(new _Member());
        _members.add(new _Member());
        _members.add(new _Member());
        _members.add(new _Member());
        _members.add(new _Member());
        _members.add(new _Member());
        _members.add(new _Member());
        _members.add(new _Member());
        _members.add(new _Member());
    }

    List _geteSelectedContacts() {
        List contacts = [];

        _members.forEach((_Member member) {
            if (member.selected) contacts.add(member.contact);
        });

        return contacts;
    } 
}
