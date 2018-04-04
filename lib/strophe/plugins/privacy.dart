import 'package:localsocialnetwork/strophe/core.dart';
import 'package:localsocialnetwork/strophe/enums.dart';
import 'package:localsocialnetwork/strophe/plugins/plugins.dart';

class PrivacyPlugin extends PluginClass {
  /** Variable: lists
   *  Available privacy lists
   */
  var lists = {};
  /** PrivateVariable: _default
   *  Default privacy list
   */
  var _default = null;
  /** PrivateVariable: _active
   *  Active privacy list
   */
  var _active = null;
  /** PrivateVariable: _isInitialized
   *  If lists were pulled from the server, and plugin is ready to work with those.
   */
  bool _isInitialized = false;
  Function _listChangeCallback;
  init(StropheConnection conn) {
    this.connection = conn;
    this._listChangeCallback = null;
    Strophe.addNamespace('PRIVACY', "jabber:iq:privacy");
  }

  bool isInitialized() {
    return this._isInitialized;
  }

  /** Function: getListNames
   *  Initial call to get all list names.
   *
   *  This has to be called before any actions with lists. This is separated from init method, to be able to put
   *  callbacks on the success and fail events.
   *
   *  Params:
   *    (Function) successCallback - Called upon successful deletion.
   *    (Function) failCallback - Called upon fail deletion.
   *    (Function) listChangeCallback - Called upon list change.
   */
  getListNames(successCallback, failCallback, listChangeCallback) {
    this._listChangeCallback = listChangeCallback;
    this.connection.sendIQ(
        Strophe.$iq({
          'type': "get",
          'id': this.connection.getUniqueId("privacy")
        }).c("query", {'xmlns': Strophe.NS['PRRIVACY']}).tree(), (stanza) {
      var _lists = this.lists;
      this.lists = {};
      var listNames = stanza.getElementsByTagName("list");
      for (int i = 0; i < listNames.length; ++i) {
        var listName = listNames[i].getAttribute("name");
        if (_lists[listName] != null)
          this.lists[listName] = _lists[listName];
        else
          this.lists[listName] = new PrivacyList(listName, false);
        this.lists[listName]._isPulled = false;
      }
      var activeNode = stanza.getElementsByTagName("active");
      if (activeNode.length == 1)
        this._active = activeNode[0].getAttribute("name");
      var defaultNode = stanza.getElementsByTagName("default");
      if (defaultNode.length == 1)
        this._default = defaultNode[0].getAttribute("name");
      this._isInitialized = true;
      if (successCallback)
        try {
          successCallback();
        } catch (e) {
          Strophe.error(
              "Error while processing callback privacy list names pull.");
        }
    }, failCallback);
  }

  /** Function: newList
   *  Create new named list.
   *
   *  Params:
   *    (String) name - New List name.
   *
   *  Returns:
   *    New list, or existing list if it exists.
   */
  newList(name) {
    if (this.lists[name] == null)
      this.lists[name] = new PrivacyList(name, true);
    return this.lists[name];
  }

  /** Function: newItem
   *  Create new item.
   *
   *  Params:
   *    (String) type - Type of item.
   *    (String) value - Value of item.
   *    (String) action - Action for the matching.
   *    (String) order - Order of rule.
   *    (String) blocked - Block list.
   *
   *  Returns:
   *    New list, or existing list if it exists.
   */
  newItem(type, value, action, order, blocked) {
    var item = new Item();
    item.type = type;
    item.value = value;
    item.action = action;
    item.order = order;
    item.blocked = blocked;
    return item;
  }

  /** Function: deleteList
   *  Delete list.
   *
   *  Params:
   *    (String) name - List name.
   *    (Function) successCallback - Called upon successful deletion.
   *    (Function) failCallback - Called upon fail deletion.
   */
  deleteList(name, successCallback, failCallback) {
    this.connection.sendIQ(
        Strophe.$iq({
          'type': "set",
          'id': this.connection.getUniqueId("privacy")
        }).c("query", {'xmlns': Strophe.NS['PRIVACY']}).c(
            "list", {'name': name}).tree(), () {
      this.lists.remove(name);
      if (successCallback)
        try {
          successCallback();
        } catch (e) {
          Strophe.error("Exception while running callback after removing list");
        }
    }, failCallback);
  }

  /** Function: saveList
   *  Saves list.
   *
   *  Params:
   *    (String) name - List name.
   *    (Function) successCallback - Called upon successful setting.
   *    (Function) failCallback - Called upon fail setting.
   *
   *  Returns:
   *    True if list is ok, and is sent to server, false otherwise.
   */
  saveList(name, successCallback, failCallback) {
    if (this.lists[name] == null) {
      Strophe.error("Trying to save uninitialized list");
      throw {'error': "List not found"};
    }
    var listModel = this.lists[name];
    if (!listModel.validate()) return false;
    var listIQ = Strophe
        .$iq({'type': "set", 'id': this.connection.getUniqueId("privacy")});
    StanzaBuilder list = listIQ
        .c("query", {'xmlns': Strophe.NS['PRIVACY']}).c("list", {name: name});
    var count = listModel.items.length;
    for (int i = 0; i < count; ++i) {
      var item = listModel.items[i];
      var itemNode =
          list.c("item", {'action': item.action, 'order': item.order});
      if (item.type != "")
        itemNode.attrs({'type': item.type, 'value': item.value});
      if (item.blocked && item.blocked.length > 0) {
        var blockCount = item.blocked.length;
        for (var j = 0; j < blockCount; ++j) itemNode.c(item.blocked[j]).up();
      }
      itemNode.up();
    }
    this.connection.sendIQ(listIQ.tree(), () {
      listModel._isPulled = true;
      if (successCallback)
        try {
          successCallback();
        } catch (e) {
          Strophe.error("Exception in callback when saving list " + name);
        }
    }, failCallback);
    return true;
  }

  /** Function: loadList
   *  Loads list from server
   *
   *  Params:
   *    (String) name - List name.
   *    (Function) successCallback - Called upon successful load.
   *    (Function) failCallback - Called upon fail load.
   */
  loadList(name, successCallback, failCallback) {
    this.connection.sendIQ(
        Strophe.$iq({
          'type': "get",
          'id': this.connection.getUniqueId("privacy")
        }).c("query", {'xmlns': Strophe.NS['PRIVACY']}).c(
            "list", {'name': name}).tree(), (stanza) {
      var lists = stanza.getElementsByTagName("list");
      var listsSize = lists.length;
      for (var i = 0; i < listsSize; ++i) {
        var list = lists[i];
        var listModel = this.newList(list.getAttribute("name"));
        listModel.items = [];
        var items = list.getElementsByTagName("item");
        var itemsSize = items.length;
        for (var j = 0; j < itemsSize; ++j) {
          var item = items[j];
          var blocks = [];
          var blockNodes = item.childNodes;
          var nodesSize = blockNodes.length;
          for (var k = 0; k < nodesSize; ++k)
            blocks.add(blockNodes[k].nodeName);
          listModel.items.push(this.newItem(
              item.getAttribute('type'),
              item.getAttribute('value'),
              item.getAttribute('action'),
              item.getAttribute('order'),
              blocks));
        }
      }
      this.lists[name];
      if (successCallback)
        try {
          successCallback();
        } catch (e) {
          Strophe.error("Exception while running callback after loading list");
        }
    }, failCallback);
  }

  /** Function: setActive
   *  Sets given list as active.
   *
   *  Params:
   *    (String) name - List name.
   *    (Function) successCallback - Called upon successful setting.
   *    (Function) failCallback - Called upon fail setting.
   */
  setActive(String name, successCallback, failCallback) {
    StanzaBuilder iq = Strophe
        .$iq({'type': "set", 'id': this.connection.getUniqueId("privacy")}).c(
            "query", {'xmlns': Strophe.NS['PRIVACY']}).c("active");
    if (name != null && name.isNotEmpty) iq.attrs({'name': name});
    this.connection.sendIQ(iq.tree(), () {
      this._active = name;
      if (successCallback)
        try {
          successCallback();
        } catch (e) {
          Strophe.error(
              "Exception while running callback after setting active list");
        }
    }, failCallback);
  }

  /** Function: getActive
   *  Returns currently active list of null.
   */
  getActive() {
    return this._active;
  }

  /** Function: setDefault
   *  Sets given list as default.
   *
   *  Params:
   *    (String) name - List name.
   *    (Function) successCallback - Called upon successful setting.
   *    (Function) failCallback - Called upon fail setting.
   */
  setDefault(String name, successCallback, failCallback) {
    StanzaBuilder iq = Strophe
        .$iq({'type': "set", 'id': this.connection.getUniqueId("privacy")}).c(
            "query", {'xmlns': Strophe.NS['PRIVACY']}).c("default");
    if (name != null && name.isNotEmpty) iq.attrs({name: name});
    this.connection.sendIQ(iq.tree(), () {
      this._default = name;
      if (successCallback)
        try {
          successCallback();
        } catch (e) {
          Strophe.error(
              "Exception while running callback after setting default list");
        }
    }, failCallback);
  }

  /** Function: getDefault
   *  Returns currently default list of null.
   */
  getDefault() {
    return this._default;
  }
}

/**
 * Class: Item
 * Describes single rule.
 */
class Item {
  /** Variable: type
   *  One of [jid, group, subscription].
   */
  var type = null;
  var value = null;
  /** Variable: action
   *  One of [allow, deny].
   *
   *  Not null. Action to be execute.
   */
  var action = null;
  /** Variable: order
   *  The order in which privacy list items are processed.
   *
   *  Unique, not-null, non-negative integer.
   */
  var order = null;
  /** Variable: blocked
   *  List of blocked stanzas.
   *
   *  One or more of [message, iq, presence-in, presence-out]. Empty set is equivalent to all.
   */
  var blocked = [];
  /** Function: validate
 *  Checks if item is of valid structure
 */
  validate() {
    if (["jid", "group", "subscription", ""].indexOf(this.type) < 0)
      return false;
    if (this.type == "subscription") {
      if (["both", "to", "from", "none"].indexOf(this.value) < 0) return false;
    }
    if (["allow", "deny"].indexOf(this.action) < 0) return false;
    bool hasMatch = new RegExp(r"^\d+$").hasMatch(this.order);
    if (!this.order || !hasMatch) return false;
    if (this.blocked.length > 0) {
      //if(typeof(this.blocked) != "object") return false;
      List<String> possibleBlocks = [
        "message",
        "iq",
        "presence-in",
        "presence-out"
      ];
      var blockCount = this.blocked.length;
      for (int i = 0; i < blockCount; ++i) {
        if (possibleBlocks.indexOf(this.blocked[i]) < 0) return false;
        possibleBlocks.remove(this.blocked[i]);
      }
    }
    return true;
  }

/** Function: copy
 *  Copy one item into another.
 */
  copy(item) {
    this.type = item.type;
    this.value = item.value;
    this.action = item.action;
    this.order = item.order;
    this.blocked = item.blocked.slice();
  }
}

/**
 * Class: List
 * Contains list of rules. There is no layering.
 */
class PrivacyList {
  PrivacyList(this._name, this._isPulled);
  /** PrivateVariable: _name
   *  List name.
   *
   *  Not changeable. Create new, copy this one, and delete, if you wish to rename.
   */
  var _name;
  /** PrivateVariable: _isPulled
   *  If list is pulled from server and up to date.
   *
   *  Is false upon first getting of list of lists, or after getting stanza about update
   */
  var _isPulled;
  /** Variable: items
   *  Items of this list.
   */
  var items = [];
  /** Function: getName
 *  Returns list name
 */
  getName() {
    return this._name;
  }

/** Function: isPulled
 *  If list is pulled from server.
 *
 * This is false for list names just taken from server. you need to make loadList to see all the contents of the list.
 * Also this is possible when list was changed somewhere else, and you've got announcement about update. Same loadList
 * is your savior.
 */
  isPulled() {
    return this._isPulled;
  }

/** Function: validate
 *  Checks if list is of valid structure
 */
  validate() {
    var orders = [];
    var itemCount = this.items.length;
    for (var i = 0; i < itemCount; ++i) {
      if (!this.items[i].validate()) return false;
      if (orders.indexOf(this.items[i].order) >= 0) return false;
      orders.add(this.items[i].order);
    }
    return true;
  }

/** Function: copy
 *  Copy all items of one list into another.
 *
 *  Params:
 *    (List) list - list to copy items from.
 */
  copy(list) {
    this.items = [];
    var l = list.items.length;
    for (var i = 0; i < l; ++i) {
      this.items[i] = new Item();
      this.items[i].copy(list.items[i]);
    }
  }
}
