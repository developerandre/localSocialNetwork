import 'package:flutter/material.dart';
import 'package:localsocialnetwork/providers/models.dart';
import 'package:localsocialnetwork/providers/xmpp.dart';
import 'package:meta/meta.dart';

class ChatMessage extends StatelessWidget {
  final AppMessage message;
  final Animation animation;

  String _jid;

  ChatMessage({@required this.message, @required this.animation}) {
    this._jid = XmppProvider.instance().jid;
  }

  @override
  Widget build(BuildContext context) {
    return new SizeTransition(
      sizeFactor:
          new CurvedAnimation(parent: animation, curve: Curves.decelerate),
      child: new Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: new Row(
          children: _jid == message.from
              ? getSentMessageLayout()
              : getReceivedMessageLayout(),
        ),
      ),
    );
  }

  List<Widget> getSentMessageLayout() {
    return <Widget>[
      new Expanded(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            new Container(
              margin: const EdgeInsets.only(top: 5.0),
              child: _buildContent(true),
            ),
          ],
        ),
      )
    ];
  }

  List<Widget> getReceivedMessageLayout() {
    return <Widget>[
      new Expanded(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Container(
              margin: const EdgeInsets.only(top: 5.0),
              child: _buildContent(false),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildContent(bool me) {
    IconData icon = Icons.crop_square;
    ;
    Color color = Colors.black;
    if (message.status == SentStatus.NO_DELIVERED)
      icon = Icons.crop_square;
    else if (message.status == SentStatus.RECEIVED)
      icon = Icons.done;
    else if (message.status == SentStatus.SENT)
      icon = Icons.done_all;
    else if (message.status == SentStatus.SEEN) {
      icon = Icons.done_all;
      color = Colors.greenAccent;
    }
    if (me) icon = null;
    DateTime dateTime = new DateTime.fromMillisecondsSinceEpoch(message.date);
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
    if (message.typeMessage == TypeMessage.IMAGE) {
      return new Image.network(
        message.url,
        width: 250.0,
      );
    } else if (message.typeMessage == TypeMessage.AUDIO) {
      return new Image.network(
        message.url,
        width: 250.0,
      );
    } else if (message.typeMessage == TypeMessage.VIDEO) {
      return new Image.network(
        message.url,
        width: 250.0,
      );
    } else if (message.typeMessage == TypeMessage.VOCAL) {
      return new Image.network(
        message.url,
        width: 250.0,
      );
    } else if (message.typeMessage == TypeMessage.CONTACT) {
      return new Image.network(
        message.url,
        width: 250.0,
      );
    } else if (message.typeMessage == TypeMessage.DOCUMENT) {
      return new Image.network(
        message.url,
        width: 250.0,
      );
    }

    return new Container(
        decoration: new BoxDecoration(
            borderRadius: new BorderRadius.circular(5.0),
            color: Colors.green.shade100),
        child: new Column(
          crossAxisAlignment:
              me ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: <Widget>[
            new Text(message.content),
            new Row(
                mainAxisAlignment:
                    me ? MainAxisAlignment.start : MainAxisAlignment.end,
                children: <Widget>[
                  new Text(time,
                      style: new TextStyle(
                          fontStyle: FontStyle.italic, fontSize: 10.0)),
                  new Icon(icon, color: color, size: 15.0)
                ])
          ],
        ));
  }
}
