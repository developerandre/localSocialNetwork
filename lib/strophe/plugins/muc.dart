import 'package:localsocialnetwork/strophe/core.dart';
import 'package:localsocialnetwork/strophe/enums.dart';
import 'package:localsocialnetwork/strophe/plugins/plugins.dart';

class MucPlugin extends PluginClass {
  /*
 *Plugin to implement the MUC extension.
   http://xmpp.org/extensions/xep-0045.html
 *Previous Author:
    Nathan Zorn <nathan.zorn@gmail.com>
 *Complete CoffeeScript rewrite:
    Andreas Guth <guth@dbis.rwth-aachen.de>
 */

  Map rooms = {};
  List roomNames = [];
  var _muc_handler;
  /*Function
  Initialize the MUC plugin. Sets the correct connection object and
  extends the namesace.
   */
  init(StropheConnection conn) {
    this.connection = conn;
    this._muc_handler = null;
    Strophe.addNamespace('MUC_OWNER', Strophe.NS['MUC'] + "#owner");
    Strophe.addNamespace('MUC_ADMIN', Strophe.NS['MUC'] + "#admin");
    Strophe.addNamespace('MUC_USER', Strophe.NS['MUC'] + "#user");
    Strophe.addNamespace('MUC_ROOMCONF', Strophe.NS['MUC'] + "#roomconfig");
    return Strophe.addNamespace('MUC_REGISTER', "jabber:iq:register");
  }

  /*Function
  Join a multi-user chat room
  Parameters:
  (String) room - The multi-user chat room to join.
  (String) nick - The nickname to use in the chat room. Optional
  (Function) msg_handler_cb - The  call to handle messages from the
  specified chat room.
  (Function) pres_handler_cb - The  call back to handle presence
  in the chat room.
  (Function) roster_cb - The  call to handle roster info in the chat room
  (String) password - The optional password to use. (password protected
  rooms only)
  (Object) history_attrs - Optional attributes for retrieving history
  (XML DOM Element) extended_presence - Optional XML for extending presence
   */
  join(
      String room,
      String nick,
      Function msg_handler_cb,
      Function pres_handler_cb,
      Function roster_cb,
      String password,
      Map history_attrs,
      extended_presence) {
    var msg, room_nick;
    room_nick = this.test_append_nick(room, nick);
    msg = Strophe.$pres({'from': this.connection.jid, 'to': room_nick}).c(
        "x", {'xmlns': Strophe.NS['MUC']});
    if (history_attrs != null) {
      msg = msg.c("history", history_attrs).up();
    }
    if (password != null) {
      msg.cnode(Strophe.xmlElement("password", attrs: [], text: password));
    }
    if (extended_presence != null) {
      msg.up().cnode(extended_presence);
    }
    if (this._muc_handler == null) {
      this._muc_handler = this.connection.addHandler((elem) {
        return (stanza) {
          var from, handler, handlers, i, id, len, roomname, x, xmlns, xquery;
          from = stanza.getAttribute('from');
          if (!from) {
            return true;
          }
          roomname = from.split("/")[0];
          if (!elem.rooms[roomname]) {
            return true;
          }
          room = elem.rooms[roomname];
          handlers = {};
          if (stanza.nodeName == "message") {
            handlers = room._message_handlers;
          } else if (stanza.nodeName == "presence") {
            xquery = stanza.getElementsByTagName("x");
            if (xquery.length > 0) {
              for (int i = 0, len = xquery.length; i < len; i++) {
                x = xquery[i];
                xmlns = x.getAttribute("xmlns");
                if (xmlns && xmlns.match(Strophe.NS['MUC'])) {
                  handlers = room._presence_handlers;
                  break;
                }
              }
            }
          }
          for (id in handlers) {
            handler = handlers[id];
            if (!handler(stanza, room)) {
              handlers.remove(id);
            }
          }
          return true;
        };
      }, null, null);
    }
    if (!this.rooms.hasOwnProperty(room)) {
      this.rooms[room] = new XmppRoom(this, room, nick, password);
      if (pres_handler_cb != null) {
        this.rooms[room].addHandler('presence', pres_handler_cb);
      }
      if (msg_handler_cb != null) {
        this.rooms[room].addHandler('message', msg_handler_cb);
      }
      if (roster_cb != null) {
        this.rooms[room].addHandler('roster', roster_cb);
      }
      this.roomNames.add(room);
    }
    return this.connection.send(msg);
  }

  /*Function
  Leave a multi-user chat room
  Parameters:
  (String) room - The multi-user chat room to leave.
  (String) nick - The nick name used in the room.
  (Function) handler_cb - Optional  to handle the successful leave.
  (String) exit_msg - optional exit message.
  Returns:
  iqid - The unique id for the room leave.
   */
  leave(room, nick, handler_cb, exit_msg) {
    var id, presence, presenceid, room_nick;
    id = this.roomNames.indexOf(room);
    this.rooms.remove(room);
    if (id >= 0) {
      this.roomNames.removeAt(id);
      if (this.roomNames.length == 0) {
        this.connection.deleteHandler(this._muc_handler);
        this._muc_handler = null;
      }
    }
    room_nick = this.test_append_nick(room, nick);
    presenceid = this.connection.getUniqueId();
    presence = Strophe.$pres({
      'type': "unavailable",
      'id': presenceid,
      'from': this.connection.jid,
      'to': room_nick
    });
    if (exit_msg != null) {
      presence.c("status", exit_msg);
    }
    if (handler_cb != null) {
      this
          .connection
          .addHandler(handler_cb, null, "presence", null, presenceid);
    }
    this.connection.send(presence);
    return presenceid;
  }

  /*Function
  Parameters:
  (String) room - The multi-user chat room name.
  (String) nick - The nick name used in the chat room.
  (String) message - The plaintext message to send to the room.
  (String) html_message - The message to send to the room with html markup.
  (String) type - "groupchat" for group chat messages o
                  "chat" for private chat messages
  Returns:
  msgiq - the unique id used to send the message
   */
  message(room, nick, message, html_message, type, msgid) {
    var msg, parent, room_nick;
    room_nick = this.test_append_nick(room, nick);
    type = type ?? (nick != null ? "chat" : "groupchat");
    msgid = msgid ?? this.connection.getUniqueId();
    msg = Strophe
        .$msg({
          'to': room_nick,
          'from': this.connection.jid,
          'type': type,
          'id': msgid
        })
        .c("body")
        .t(message);
    msg.up();
    if (html_message != null) {
      msg.c("html", {'xmlns': Strophe.NS['XHTML_IM']}).c(
          "body", {'xmlns': Strophe.NS['XHTML']}).h(html_message);
      if (msg.node.childNodes.length == 0) {
        parent = msg.node.parentNode;
        msg.up().up();
        msg.node.removeChild(parent);
      } else {
        msg.up().up();
      }
    }
    msg.c("x", {'xmlns': "jabber:x:event"}).c("composing");
    this.connection.send(msg);
    return msgid;
  }

  /*Function
  Convenience Function to send a Message to all Occupants
  Parameters:
  (String) room - The multi-user chat room name.
  (String) message - The plaintext message to send to the room.
  (String) html_message - The message to send to the room with html markup.
  (String) msgid - Optional unique ID which will be set as the 'id' attribute of the stanza
  Returns:
  msgiq - the unique id used to send the message
   */
  groupchat(room, message, html_message, msgid) {
    return this.message(room, null, message, html_message, 0, msgid);
  }

  /*Function
  Send a mediated invitation.
  Parameters:
  (String) room - The multi-user chat room name.
  (String) receiver - The invitation's receiver.
  (String) reason - Optional reason for joining the room.
  Returns:
  msgiq - the unique id used to send the invitation
   */
  invite(room, receiver, reason) {
    var invitation, msgid;
    msgid = this.connection.getUniqueId();
    invitation = Strophe
        .$msg({'from': this.connection.jid, 'to': room, 'id': msgid}).c('x',
            {'xmlns': Strophe.NS['MUC_USER']}).c('invite', {'to': receiver});
    if (reason != null) {
      invitation.c('reason', reason);
    }
    this.connection.send(invitation);
    return msgid;
  }

  /*Function
  Send a mediated multiple invitation.
  Parameters:
  (String) room - The multi-user chat room name.
  (Array) receivers - The invitation's receivers.
  (String) reason - Optional reason for joining the room.
  Returns:
  msgiq - the unique id used to send the invitation
   */
  multipleInvites(room, receivers, reason) {
    var i, invitation, len, msgid, receiver;
    msgid = this.connection.getUniqueId();
    invitation = Strophe
        .$msg({'from': this.connection.jid, 'to': room, 'id': msgid}).c(
            'x', {'xmlns': Strophe.NS['MUC_USER']});
    for (int i = 0, len = receivers.length; i < len; i++) {
      receiver = receivers[i];
      invitation.c('invite', {'to': receiver});
      if (reason != null) {
        invitation.c('reason', reason);
        invitation.up();
      }
      invitation.up();
    }
    this.connection.send(invitation);
    return msgid;
  }

  /*Function
  Send a direct invitation.
  Parameters:
  (String) room - The multi-user chat room name.
  (String) receiver - The invitation's receiver.
  (String) reason - Optional reason for joining the room.
  (String) password - Optional password for the room.
  Returns:
  msgiq - the unique id used to send the invitation
   */
  directInvite(room, receiver, reason, password) {
    var attrs, invitation, msgid;
    msgid = this.connection.getUniqueId();
    attrs = {'xmlns': 'jabber:x:conference', 'jid': room};
    if (reason != null) {
      attrs.reason = reason;
    }
    if (password != null) {
      attrs.password = password;
    }
    invitation = Strophe
        .$msg({'from': this.connection.jid, 'to': receiver, 'id': msgid}).c(
            'x', attrs);
    this.connection.send(invitation);
    return msgid;
  }

  /*Function
  Queries a room for a list of occupants
  (String) room - The multi-user chat room name.
  (Function) success_cb - Optional  to handle the info.
  (Function) error_cb - Optional  to handle an error.
  Returns:
  id - the unique id used to send the info request
   */
  queryOccupants(room, success_cb, error_cb) {
    var attrs, info;
    attrs = {'xmlns': Strophe.NS['DISCO_ITEMS']};
    info = Strophe
        .$iq({'from': this.connection.jid, 'to': room, 'type': 'get'}).c(
            'query', attrs);
    return this.connection.sendIQ(info, success_cb, error_cb);
  }

  /*Function
  Start a room configuration.
  Parameters:
  (String) room - The multi-user chat room name.
  (Function) handler_cb - Optional  to handle the config form.
  Returns:
  id - the unique id used to send the configuration request
   */
  configure(room, handler_cb, error_cb) {
    var config, stanza;
    config = Strophe.$iq({'to': room, 'type': "get"}).c(
        "query", {'xmlns': Strophe.NS['MUC_OWNER']});
    stanza = config.tree();
    return this.connection.sendIQ(stanza, handler_cb, error_cb);
  }

  /*Function
  Cancel the room configuration
  Parameters:
  (String) room - The multi-user chat room name.
  Returns:
  id - the unique id used to cancel the configuration.
   */
  cancelConfigure(room) {
    var config, stanza;
    config = Strophe.$iq({'to': room, 'type': "set"}).c("query", {
      'xmlns': Strophe.NS['MUC_OWNER']
    }).c("x", {'xmlns': "jabber:x:data", 'type': "cancel"});
    stanza = config.tree();
    return this.connection.sendIQ(stanza);
  }

  /*Function
  Save a room configuration.
  Parameters:
  (String) room - The multi-user chat room name.
  (Array) config- Form Object or an array of form elements used to configure the room.
  Returns:
  id - the unique id used to save the configuration.
   */
  saveConfiguration(room, config, success_cb, error_cb) {
    var conf, i, iq, len, stanza;
    iq = Strophe.$iq({'to': room, 'type': "set"}).c(
        "query", {'xmlns': Strophe.NS['MUC_OWNER']});
    iq.c("x", {'xmlns': "jabber:x:data", 'type': "submit"});
    for (int i = 0, len = config.length; i < len; i++) {
      conf = config[i];
      iq.cnode(conf).up();
    }
    stanza = iq.tree();
    return this.connection.sendIQ(stanza, success_cb, error_cb);
  }

  /*Function
  Parameters:
  (String) room - The multi-user chat room name.
  Returns:
  id - the unique id used to create the chat room.
   */
  createInstantRoom(room, success_cb, error_cb) {
    var roomiq;
    roomiq = Strophe.$iq({'to': room, 'type': "set"}).c("query", {
      'xmlns': Strophe.NS['MUC_OWNER']
    }).c("x", {'xmlns': "jabber:x:data", 'type': "submit"});
    return this.connection.sendIQ(roomiq.tree(), success_cb, error_cb);
  }

  /*Function
  Parameters:
  (String) room - The multi-user chat room name.
  (Object) config - the configuration. ex: {"muc#roomconfig_publicroom": "0", "muc#roomconfig_persistentroom": "1"}
  Returns:
  id - the unique id used to create the chat room.
   */
  createConfiguredRoom(room, Map<String, String> config, success_cb, error_cb) {
    var k, roomiq, v;
    roomiq = Strophe.$iq({'to': room, 'type': "set"}).c("query", {
      'xmlns': Strophe.NS['MUC_OWNER']
    }).c("x", {'xmlns': "jabber:x:data", 'type': "submit"});
    roomiq
        .c('field', {'var': 'FORM_TYPE'})
        .c('value')
        .t('http://jabber.org/protocol/muc#roomconfig')
        .up()
        .up();
    config.forEach((String key, String value) {
      roomiq.c('field', {'var': key}).c('value').t(value).up().up();
    });
    return this.connection.sendIQ(roomiq.tree(), success_cb, error_cb);
  }

  /*Function
  Set the topic of the chat room.
  Parameters:
  (String) room - The multi-user chat room name.
  (String) topic - Topic message.
   */
  setTopic(room, topic) {
    var msg;
    msg = Strophe
        .$msg({'to': room, 'from': this.connection.jid, 'type': "groupchat"}).c(
            "subject", {'xmlns': "jabber:client"}).t(topic);
    return this.connection.send(msg.tree());
  }

  /*Function
  Internal Function that Changes the role or affiliation of a member
  of a MUC room. This  is used by modifyRole and modifyAffiliation.
  The modification can only be done by a room moderator. An error will be
  returned if the user doesn't have permission.
  Parameters:
  (String) room - The multi-user chat room name.
  (Object) item - Object with nick and role or jid and affiliation attribute
  (String) reason - Optional reason for the change.
  (Function) handler_cb - Optional callback for success
  (Function) error_cb - Optional callback for error
  Returns:
  iq - the id of the mode change request.
   */
  _modifyPrivilege(room, item, reason, handler_cb, error_cb) {
    var iq;
    iq = Strophe.$iq({'to': room, 'type': "set"}).c(
        "query", {'xmlns': Strophe.NS['MUC_ADMIN']}).cnode(item.node);
    if (reason != null) {
      iq.c("reason", reason);
    }
    return this.connection.sendIQ(iq.tree(), handler_cb, error_cb);
  }

  /*Function
  Changes the role of a member of a MUC room.
  The modification can only be done by a room moderator. An error will be
  returned if the user doesn't have permission.
  Parameters:
  (String) room - The multi-user chat room name.
  (String) nick - The nick name of the user to modify.
  (String) role - The new role of the user.
  (String) affiliation - The new affiliation of the user.
  (String) reason - Optional reason for the change.
  (Function) handler_cb - Optional callback for success
  (Function) error_cb - Optional callback for error
  Returns:
  iq - the id of the mode change request.
   */
  modifyRole(room, nick, role, reason, handler_cb, error_cb) {
    var item;
    item = Strophe.$build("item", {nick: nick, role: role});
    return this._modifyPrivilege(room, item, reason, handler_cb, error_cb);
  }

  kick(room, nick, reason, handler_cb, error_cb) {
    return this.modifyRole(room, nick, 'none', reason, handler_cb, error_cb);
  }

  voice(room, nick, reason, handler_cb, error_cb) {
    return this
        .modifyRole(room, nick, 'participant', reason, handler_cb, error_cb);
  }

  mute(room, nick, reason, handler_cb, error_cb) {
    return this.modifyRole(room, nick, 'visitor', reason, handler_cb, error_cb);
  }

  op(room, nick, reason, handler_cb, error_cb) {
    return this
        .modifyRole(room, nick, 'moderator', reason, handler_cb, error_cb);
  }

  deop(room, nick, reason, handler_cb, error_cb) {
    return this
        .modifyRole(room, nick, 'participant', reason, handler_cb, error_cb);
  }

  /*Function
  Changes the affiliation of a member of a MUC room.
  The modification can only be done by a room moderator. An error will be
  returned if the user doesn't have permission.
  Parameters:
  (String) room - The multi-user chat room name.
  (String) jid  - The jid of the user to modify.
  (String) affiliation - The new affiliation of the user.
  (String) reason - Optional reason for the change.
  (Function) handler_cb - Optional callback for success
  (Function) error_cb - Optional callback for error
  Returns:
  iq - the id of the mode change request.
   */
  modifyAffiliation(room, jid, affiliation, reason, handler_cb, error_cb) {
    var item;
    item = Strophe.$build("item", {jid: jid, affiliation: affiliation});
    return this._modifyPrivilege(room, item, reason, handler_cb, error_cb);
  }

  ban(room, jid, reason, handler_cb, error_cb) {
    return this
        .modifyAffiliation(room, jid, 'outcast', reason, handler_cb, error_cb);
  }

  member(room, jid, reason, handler_cb, error_cb) {
    return this
        .modifyAffiliation(room, jid, 'member', reason, handler_cb, error_cb);
  }

  revoke(room, jid, reason, handler_cb, error_cb) {
    return this
        .modifyAffiliation(room, jid, 'none', reason, handler_cb, error_cb);
  }

  owner(room, jid, reason, handler_cb, error_cb) {
    return this
        .modifyAffiliation(room, jid, 'owner', reason, handler_cb, error_cb);
  }

  admin(room, jid, reason, handler_cb, error_cb) {
    return this
        .modifyAffiliation(room, jid, 'admin', reason, handler_cb, error_cb);
  }

  /*Function
  Change the current users nick name.
  Parameters:
  (String) room - The multi-user chat room name.
  (String) user - The new nick name.
   */
  changeNick(room, user) {
    var presence, room_nick;
    room_nick = this.test_append_nick(room, user);
    presence = Strophe.$pres({
      'from': this.connection.jid,
      'to': room_nick,
      'id': this.connection.getUniqueId()
    });
    return this.connection.send(presence.tree());
  }

  /*Function
  Change the current users status.
  Parameters:
  (String) room - The multi-user chat room name.
  (String) user - The current nick.
  (String) show - The new show-text.
  (String) status - The new status-text.
   */
  setStatus(room, user, show, status) {
    var presence, room_nick;
    room_nick = this.test_append_nick(room, user);
    presence = Strophe.$pres({'from': this.connection.jid, 'to': room_nick});
    if (show != null) {
      presence.c('show', show).up();
    }
    if (status != null) {
      presence.c('status', status);
    }
    return this.connection.send(presence.tree());
  }

  /*Function
  Registering with a room.
  @see http://xmpp.org/extensions/xep-0045.html#register
  Parameters:
  (String) room - The multi-user chat room name.
  (Function) handle_cb - Function to call for room list return.
  (Function) error_cb - Function to call on error.
   */
  registrationRequest(room, handle_cb, error_cb) {
    var iq;
    iq = Strophe
        .$iq({'to': room, 'from': this.connection.jid, 'type': "get"}).c(
            "query", {'xmlns': Strophe.NS['MUC_REGISTER']});
    return this.connection.sendIQ(iq, (stanza) {
      var $field, $fields, field, fields, i, len, length;
      $fields = stanza.getElementsByTagName('field');
      length = $fields.length;
      fields = {'required': [], 'optional': []};
      for (int i = 0, len = $fields.length; i < len; i++) {
        $field = $fields[i];
        field = {
          "var": $field.getAttribute('var'),
          'label': $field.getAttribute('label'),
          'type': $field.getAttribute('type')
        };
        if ($field.getElementsByTagName('required').length > 0) {
          fields.required.add(field);
        } else {
          fields.optional.add(field);
        }
      }
      return handle_cb(fields);
    }, error_cb);
  }

  /*Function
  Submits registration form.
  Parameters:
  (String) room - The multi-user chat room name.
  (Function) handle_cb - Function to call for room list return.
  (Function) error_cb - Function to call on error.
   */
  submitRegistrationForm(room, fields, handle_cb, error_cb) {
    var iq, key, val;
    iq = Strophe.$iq({'to': room, 'type': "set"}).c(
        "query", {'xmlns': Strophe.NS['MUC_REGISTER']});
    iq.c("x", {'xmlns': "jabber:x:data", 'type': "submit"});
    iq
        .c('field', {'var': 'FORM_TYPE'})
        .c('value')
        .t('http://jabber.org/protocol/muc#register')
        .up()
        .up();
    for (key in fields) {
      val = fields[key];
      iq.c('field', {'var': key}).c('value').t(val).up().up();
    }
    return this.connection.sendIQ(iq, handle_cb, error_cb);
  }

  /*Function
  List all chat room available on a server.
  Parameters:
  (String) server - name of chat server.
  (String) handle_cb - Function to call for room list return.
  (String) error_cb - Function to call on error.
   */
  listRooms(server, handle_cb, error_cb) {
    var iq;
    iq = Strophe
        .$iq({'to': server, 'from': this.connection.jid, 'type': "get"}).c(
            "query", {'xmlns': Strophe.NS['DISCO_ITEMS']});
    return this.connection.sendIQ(iq, handle_cb, error_cb);
  }

  test_append_nick(room, nick) {
    var domain, node;
    node = Strophe.escapeNode(Strophe.getNodeFromJid(room));
    domain = Strophe.getDomainFromJid(room);
    return node + "@" + domain + (nick != null ? "/" + nick : "");
  }
}

class XmppRoom {
  Map client;

  String name;

  var nick;

  var password;

  Map roster;

  Map _message_handlers;

  Map _presence_handlers;

  Map _roster_handlers;

  int _handler_ids;

  XmppRoom(client, name, nick1, password1) {
    this.client = client;
    this.name = name;
    this.nick = nick1;
    this.password = password1;
    this.roster = {};
    this._message_handlers = {};
    this._presence_handlers = {};
    this._roster_handlers = {};
    this._handler_ids = 0;
    if (this.client['muc']) {
      this.client = this.client['muc'];
    }
    this.name = Strophe.getBareJidFromJid(this.name);
    this.addHandler('presence', this._roomRosterHandler);
  }

  join(msg_handler_cb, pres_handler_cb, roster_cb) {
    return this.client.join(this.name, this.nick, msg_handler_cb,
        pres_handler_cb, roster_cb, this.password);
  }

  leave(handler_cb, message) {
    this.client.leave(this.name, this.nick, handler_cb, message);
    return this.client['rooms'].remove(this.name);
  }

  message(nick, message, html_message, type) {
    return this.client.message(this.name, nick, message, html_message, type);
  }

  groupchat(message, html_message) {
    return this.client.groupchat(this.name, message, html_message);
  }

  invite(receiver, reason) {
    return this.client.invite(this.name, receiver, reason);
  }

  multipleInvites(receivers, reason) {
    return this.client.invite(this.name, receivers, reason);
  }

  directInvite(receiver, reason) {
    return this.client['directInvite'](
        this.name, receiver, reason, this.password);
  }

  configure(handler_cb) {
    return this.client['configure'](this.name, handler_cb);
  }

  cancelConfigure() {
    return this.client.cancelConfigure(this.name);
  }

  saveConfiguration(config) {
    return this.client.saveConfiguration(this.name, config);
  }

  queryOccupants(success_cb, error_cb) {
    return this.client.queryOccupants(this.name, success_cb, error_cb);
  }

  setTopic(topic) {
    return this.client.setTopic(this.name, topic);
  }

  modifyRole(nick, role, reason, success_cb, error_cb) {
    return this
        .client
        .modifyRole(this.name, nick, role, reason, success_cb, error_cb);
  }

  kick(nick, reason, handler_cb, error_cb) {
    return this.client.kick(this.name, nick, reason, handler_cb, error_cb);
  }

  voice(nick, reason, handler_cb, error_cb) {
    return this.client.voice(this.name, nick, reason, handler_cb, error_cb);
  }

  mute(nick, reason, handler_cb, error_cb) {
    return this.client.mute(this.name, nick, reason, handler_cb, error_cb);
  }

  op(nick, reason, handler_cb, error_cb) {
    return this.client.op(this.name, nick, reason, handler_cb, error_cb);
  }

  deop(nick, reason, handler_cb, error_cb) {
    return this.client.deop(this.name, nick, reason, handler_cb, error_cb);
  }

  modifyAffiliation(jid, affiliation, reason, success_cb, error_cb) {
    return this.client.modifyAffiliation(
        this.name, jid, affiliation, reason, success_cb, error_cb);
  }

  ban(jid, reason, handler_cb, error_cb) {
    return this.client.ban(this.name, jid, reason, handler_cb, error_cb);
  }

  member(jid, reason, handler_cb, error_cb) {
    return this.client.member(this.name, jid, reason, handler_cb, error_cb);
  }

  revoke(jid, reason, handler_cb, error_cb) {
    return this.client.revoke(this.name, jid, reason, handler_cb, error_cb);
  }

  owner(jid, reason, handler_cb, error_cb) {
    return this.client.owner(this.name, jid, reason, handler_cb, error_cb);
  }

  admin(jid, reason, handler_cb, error_cb) {
    return this.client.admin(this.name, jid, reason, handler_cb, error_cb);
  }

  changeNick(nick1) {
    this.nick = nick1;
    return this.client.changeNick(this.name, nick);
  }

  setStatus(show, status) {
    return this.client.setStatus(this.name, this.nick, show, status);
  }

  /*Function
  Adds a handler to the MUC room.
    Parameters:
  (String) handler_type - 'message', 'presence' or 'roster'.
  (Function) handler - The handler .
  Returns:
  id - the id of handler.
   */

  addHandler(handler_type, handler) {
    var id;
    id = this._handler_ids++;
    switch (handler_type) {
      case 'presence':
        this._presence_handlers[id] = handler;
        break;
      case 'message':
        this._message_handlers[id] = handler;
        break;
      case 'roster':
        this._roster_handlers[id] = handler;
        break;
      default:
        this._handler_ids--;
        return null;
    }
    return id;
  }

  /*Function
  Removes a handler from the MUC room.
  This  takes ONLY ids returned by the addHandler 
  of this room. passing handler ids returned by connection.addHandler
  may brake things!
    Parameters:
  (number) id - the id of the handler
   */

  removeHandler(id) {
    this._presence_handlers.remove(id);
    this._message_handlers.remove(id);
    return this._roster_handlers.remove(id);
  }

  /*Function
  Creates and adds an Occupant to the Room Roster.
    Parameters:
  (Object) data - the data the Occupant is filled with
  Returns:
  occ - the created Occupant.
   */

  _addOccupant(data) {
    var occ;
    occ = new Occupant(data, this);
    this.roster[occ.nick] = occ;
    return occ;
  }

  /*Function
  The standard handler that managed the Room Roster.
    Parameters:
  (Object) pres - the presence stanza containing user information
   */

  _roomRosterHandler(pres) {
    var data, handler, id, newnick, nick, ref;
    data = _parsePresence(pres);
    nick = data.nick;
    newnick = data.newnick || null;
    switch (data.type) {
      case 'error':
        return true;
      case 'unavailable':
        if (newnick) {
          data.nick = newnick;
          if (this.roster[nick] && this.roster[newnick]) {
            this.roster[nick].update(this.roster[newnick]);
            this.roster[newnick] = this.roster[nick];
          }
          if (this.roster[nick] && !this.roster[newnick]) {
            this.roster[newnick] = this.roster[nick].update(data);
          }
        }
        this.roster.remove(nick);
        break;
      default:
        if (this.roster[nick]) {
          this.roster[nick].update(data);
        } else {
          this._addOccupant(data);
        }
    }
    ref = this._roster_handlers;
    for (id in ref) {
      handler = ref[id];
      if (!handler(this.roster, this)) {
        this._roster_handlers.remove(id);
      }
    }
    return true;
  }

  /*Function
  Parses a presence stanza
    Parameters:
  (Object) data - the data extracted from the presence stanza
   */

  _parsePresence(pres) {
    var c, c2, data, i, j, len, len1, ref, ref1, ref2;
    data = {};
    data.nick = Strophe.getResourceFromJid(pres.getAttribute("from"));
    data.type = pres.getAttribute("type");
    data.states = [];
    ref = pres.childNodes;
    for (int i = 0, len = ref.length; i < len; i++) {
      c = ref[i];
      switch (c.nodeName) {
        case "error":
          data.errorcode = c.getAttribute("code");
          data.error = (ref1 = c.childNodes[0]) != null ? ref1.nodeName : 0;
          break;
        case "status":
          data.status = c.textContent || null;
          break;
        case "show":
          data.show = c.textContent || null;
          break;
        case "x":
          if (c.getAttribute("xmlns") == Strophe.NS['MUC_USER']) {
            ref2 = c.childNodes;
            for (int j = 0, len1 = ref2.length; j < len1; j++) {
              c2 = ref2[j];
              switch (c2.nodeName) {
                case "item":
                  data.affiliation = c2.getAttribute("affiliation");
                  data.role = c2.getAttribute("role");
                  data.jid = c2.getAttribute("jid");
                  data.newnick = c2.getAttribute("nick");
                  break;
                case "status":
                  if (c2.getAttribute("code")) {
                    data.states.add(c2.getAttribute("code"));
                  }
              }
            }
          }
      }
    }
    return data;

    return XmppRoom;
  }
}

class Occupant {
  var room;

  var nick;

  var jid;

  bool show;

  bool status;

  bool role;

  bool affiliation;

  Occupant(data, room1) {
    this.room = room1;
    this.update(data);
  }

  modifyRole(role, reason, success_cb, error_cb) {
    return this.room.modifyRole(this.nick, role, reason, success_cb, error_cb);
  }

  kick(reason, handler_cb, error_cb) {
    return this.room.kick(this.nick, reason, handler_cb, error_cb);
  }

  voice(reason, handler_cb, error_cb) {
    return this.room.voice(this.nick, reason, handler_cb, error_cb);
  }

  mute(reason, handler_cb, error_cb) {
    return this.room.mute(this.nick, reason, handler_cb, error_cb);
  }

  op(reason, handler_cb, error_cb) {
    return this.room.op(this.nick, reason, handler_cb, error_cb);
  }

  deop(reason, handler_cb, error_cb) {
    return this.room.deop(this.nick, reason, handler_cb, error_cb);
  }

  modifyAffiliation(affiliation, reason, success_cb, error_cb) {
    return this
        .room
        .modifyAffiliation(this.jid, affiliation, reason, success_cb, error_cb);
  }

  ban(reason, handler_cb, error_cb) {
    return this.room.ban(this.jid, reason, handler_cb, error_cb);
  }

  member(reason, handler_cb, error_cb) {
    return this.room.member(this.jid, reason, handler_cb, error_cb);
  }

  revoke(reason, handler_cb, error_cb) {
    return this.room.revoke(this.jid, reason, handler_cb, error_cb);
  }

  owner(reason, handler_cb, error_cb) {
    return this.room.owner(this.jid, reason, handler_cb, error_cb);
  }

  admin(reason, handler_cb, error_cb) {
    return this.room.admin(this.jid, reason, handler_cb, error_cb);
  }

  update(data) {
    this.nick = data.nick || null;
    this.affiliation = data.affiliation || null;
    this.role = data.role || null;
    this.jid = data.jid || null;
    this.status = data.status || null;
    this.show = data.show || null;
    return this;
  }

  //return Occupant;

}

class RoomConfig {
  List features;

  List identities;

  List x;

  RoomConfig(info) {
    if (info != null) {
      this.parse(info);
    }
  }

  parse(result) {
    var attr,
        attrs,
        child,
        field,
        i,
        identity,
        j,
        l,
        len,
        len1,
        len2,
        query,
        ref;
    query = result.getElementsByTagName("query")[0].childNodes;
    this.identities = [];
    this.features = [];
    this.x = [];
    for (int i = 0, len = query.length; i < len; i++) {
      child = query[i];
      attrs = child.attributes;
      switch (child.nodeName) {
        case "identity":
          identity = {};
          for (int j = 0, len1 = attrs.length; j < len1; j++) {
            attr = attrs[j];
            identity[attr.name] = attr.textContent;
          }
          this.identities.add(identity);
          break;
        case "feature":
          this.features.add(child.getAttribute("var"));
          break;
        case "x":
          if ((!child.childNodes[0].getAttribute("var") == 'FORM_TYPE') ||
              (!child.childNodes[0].getAttribute("type") == 'hidden')) {
            break;
          }
          ref = child.childNodes;
          for (int l = 0, len2 = ref.length; l < len2; l++) {
            field = ref[l];
            if (!field.attributes.type) {
              this.x.add({
                "var": field.getAttribute("var"),
                'label': field.getAttribute("label") ?? "",
                'value': field.firstChild.textContent ?? ""
              });
            }
          }
      }
    }
    return {
      "identities": this.identities,
      "features": this.features,
      "x": this.x
    };
  }

  //return RoomConfig;

}
