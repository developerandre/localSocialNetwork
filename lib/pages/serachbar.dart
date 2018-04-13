import 'package:flutter/material.dart';

class SearchBar extends StatefulWidget {
  final Function onTapped;

  String hint;

  SearchBar(this.onTapped, this.hint, {Key key}) : super(key: key);
  @override
  _SearchBarState createState() {
    return new _SearchBarState();
  }
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController _searchController = new TextEditingController();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _searchController.addListener(() {
      widget.onTapped(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      child: new Card(
          color: Colors.transparent,
          elevation: 0.0,
          child: new Row(
            children: <Widget>[
              new Expanded(
                  child: new TextFormField(
                autofocus: true,
                controller: _searchController,
                decoration: new InputDecoration(
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: new TextStyle(
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        fontFamily: "Serif")),
              ))
            ],
          )),
    );
  }
}
