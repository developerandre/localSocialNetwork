import 'package:localsocialnetwork/strophe/core.dart';
import 'package:localsocialnetwork/strophe/enums.dart';
import 'package:localsocialnetwork/strophe/plugins/plugins.dart';

/** File: strophe.pubsub.js
 *  A Strophe plugin for XMPP Publish-Subscribe.
 *
 *  Provides Strophe.Connection.pubsub object,
 *  parially implementing XEP 0060.
 *
 *  Strophe.Builder.prototype methods should probably move to strophe.js
 */

class PubsubBuilder extends StanzaBuilder {
  PubsubBuilder(String name, [Map<String, dynamic> attrs]) : super(name, attrs);
  /** Function: Strophe.Builder.form
 *  Add an options form child element.
 *
 *  Does not change the current element.
 *
 *  Parameters:
 *    (String) ns - form namespace.
 *    (Object) options - form properties.
 *
 *  Returns:
 *    The Strophe.Builder object.
 */
  form(String ns, Map<String, dynamic> options) {
    PubsubBuilder aX = this.cnode(Strophe
        .xmlElement('x', attrs: {"xmlns": "jabber:x:data", "type": "submit"}));
    aX
        .cnode(Strophe
            .xmlElement('field', attrs: {"var": "FORM_TYPE", "type": "hidden"}))
        .cnode(Strophe.xmlElement('value'))
        .t(ns)
        .up()
        .up();
    options.forEach((String key, value) {
      aX
          .cnode(Strophe.xmlElement('field', attrs: {"var": key}))
          .cnode(Strophe.xmlElement('value'))
          .cnode(Strophe.xmlTextNode(options[key]));
    });
    return this;
  }

/** Function: Strophe.Builder.list
 *  Add many child elements.
 *
 *  Does not change the current element.
 *
 *  Parameters:
 *    (String) tag - tag name for children.
 *    (Array) array - list of objects with format:
 *          { attrs: { [string]:[string], ... } // attributes of each tag element
 *             data: [string | XML_element] }    // contents of each tag element
 *
 *  Returns:
 *    The Strophe.Builder object.
 */
  list(String tag, List<Map<String, dynamic>> array) {
    for (int i = 0; i < array.length; ++i) {
      this.c(tag, array[i]['attrs']);
      this.cnode(array[i]['data'] is String
          ? Strophe.xmlTextNode(array[i]['data'])
          : Strophe.copyElement(array[i]['data']));
      this.up();
    }
    return this;
  }

  @override
  PubsubBuilder c(String name, [Map<String, String> attrs, dynamic text]) {
    return super.c(name, attrs, text) as PubsubBuilder;
  }

  children(Map object) {
    object.forEach((key, value) {
      if (value is List) {
        this.list(key, value);
      } else if (value is String) {
        this.c(key, {}, value);
      } else if (value is num) {
        this.c(key, {}, value.toString());
      } else if (value is Map) {
        this.c(key).children(value).up();
      } else {
        this.c(key).up();
      }
    });
    return this;
  }
}

class PubsubPlugin extends PluginClass {
  PubsubPlugin() {
    // Called by Strophe on connection event
    statusChanged = (status, condition) {
      if (this._autoService && status == Strophe.Status['CONNECTED']) {
        this.service =
            'pubsub.' + Strophe.getDomainFromJid(this.connection.jid);
        this.jid = this.connection.jid;
      }
    };
  }

// TODO Ideas Adding possible conf values?
/* Extend Strophe.Connection to have member 'pubsub'.
 */
/*
Extend connection object to have plugin name 'pubsub'.
*/
  bool _autoService = true;
  String service;
  String jid;
  Map<String, dynamic> handler = {};

  //The plugin must have the init function.
  init(StropheConnection conn) {
    this.connection = conn;

    /*
        Function used to setup plugin.
        */

    /* extend name space
        *  NS['PUBSUB'] - XMPP Publish Subscribe namespace
        *              from XEP 60.
        *
        *  NS.PUBSUB_SUBSCRIBE_OPTIONS - XMPP pubsub
        *                                options namespace from XEP 60.
        */
    Strophe.addNamespace('PUBSUB', "http://jabber.org/protocol/pubsub");
    Strophe.addNamespace('PUBSUB_SUBSCRIBE_OPTIONS',
        Strophe.NS['PUBSUB'] + "#subscribe_options");
    Strophe.addNamespace('PUBSUB_ERRORS', Strophe.NS['PUBSUB'] + "#errors");
    Strophe.addNamespace('PUBSUB_EVENT', Strophe.NS['PUBSUB'] + "#event");
    Strophe.addNamespace('PUBSUB_OWNER', Strophe.NS['PUBSUB'] + "#owner");
    Strophe.addNamespace(
        'PUBSUB_AUTO_CREATE', Strophe.NS['PUBSUB'] + "#auto-create");
    Strophe.addNamespace(
        'PUBSUB_PUBLISH_OPTIONS', Strophe.NS['PUBSUB'] + "#publish-options");
    Strophe.addNamespace(
        'PUBSUB_NODE_CONFIG', Strophe.NS['PUBSUB'] + "#node_config");
    Strophe.addNamespace('PUBSUB_CREATE_AND_CONFIGURE',
        Strophe.NS['PUBSUB'] + "#create-and-configure");
    Strophe.addNamespace('PUBSUB_SUBSCRIBE_AUTHORIZATION',
        Strophe.NS['PUBSUB'] + "#subscribe_authorization");
    Strophe.addNamespace(
        'PUBSUB_GET_PENDING', Strophe.NS['PUBSUB'] + "#get-pending");
    Strophe.addNamespace('PUBSUB_MANAGE_SUBSCRIPTIONS',
        Strophe.NS['PUBSUB'] + "#manage-subscriptions");
    Strophe.addNamespace(
        'PUBSUB_META_DATA', Strophe.NS['PUBSUB'] + "#meta-data");
    Strophe.addNamespace('ATOM', "http://www.w3.org/2005/Atom");

    if (conn.disco != null) conn.disco.addFeature(Strophe.NS['PUBSUB']);
  }

  /***Function
    Parameters:
    (String) jid - The node owner's jid.
    (String) service - The name of the pubsub service.
    */
  connect(String jid, [String service]) {
    if (service == null) {
      service = jid;
      jid = null;
    }
    this.jid = jid ?? this.connection.jid;
    this.service = service ?? null;
    this._autoService = false;
  }

  /***Function
     Parameters:
     (String) node - The name of node
     (String) handler - reference to registered strophe handler
     */
  storeHandler(String node, String handler) {
    if (!this.handler[node]) {
      this.handler[node] = [];
    }
    this.handler[node].push(handler);
  }

  /***Function
     Parameters:
     (String) node - The name of node
     */
  removeHandler(node) {
    var toberemoved = this.handler[node];
    this.handler[node] = [];

    // remove handler
    if (toberemoved && toberemoved.length > 0) {
      for (var i = 0, l = toberemoved.length; i < l; i++) {
        this.connection.deleteHandler(toberemoved[i]);
      }
    }
  }

  /***Function
    Create a pubsub node on the given service with the given node
    name.
    Parameters:
    (String) node -  The name of the pubsub node.
    (Dictionary) options -  The configuration options for the  node.
    (Function) call_back - Used to determine if node
    creation was sucessful.
    Returns:
    Iq id used to send subscription.
    */
  createNode(String node, Map<String, dynamic> options, Function callback) {
    String iqid = this.connection.getUniqueId("pubsubcreatenode");

    PubsubBuilder iq = Strophe.$iq({
      'from': this.jid,
      'to': this.service,
      'type': 'set',
      'id': iqid
    }).c('pubsub', {'xmlns': Strophe.NS['PUBSUB']}).c('create', {node: node});
    if (options != null) {
      PubsubBuilder c = iq.up().c('configure');
      c.form(Strophe.NS['PUBSUB_NODE_CONFIG'], options);
    }

    this.connection.addHandler(callback, null, 'iq', null, iqid, null);
    this.connection.send(iq.tree());
    return iqid;
  }

  /** Function: deleteNode
     *  Delete a pubsub node.
     *
     *  Parameters:
     *    (String) node -  The name of the pubsub node.
     *    (Function) call_back - Called on server response.
     *
     *  Returns:
     *    Iq id
     */
  deleteNode(node, call_back) {
    var that = this.connection;
    var iqid = that.getUniqueId("pubsubdeletenode");

    var iq = Strophe.$iq({
      'from': this.jid,
      'to': this.service,
      'type': 'set',
      'id': iqid
    }).c('pubsub', {'xmlns': Strophe.NS['PUBSUB_OWNER']}).c(
        'delete', {node: node});

    that.addHandler(call_back, null, 'iq', null, iqid, null);
    that.send(iq.tree());

    return iqid;
  }

  /** Function
     *
     * Get all nodes that currently exist.
     *
     * Parameters:
     *   (Function) success - Used to determine if node creation was sucessful.
     *   (Function) error - Used to determine if node
     * creation had errors.
     */
  discoverNodes(success, error, timeout) {
    //ask for all nodes
    var iq = Strophe
        .$iq({'from': this.jid, 'to': this.service, 'type': 'get'}).c(
            'query', {'xmlns': Strophe.NS['DISCO_ITEMS']});

    return this.connection.sendIQ(iq.tree(), success, error, timeout);
  }

  /** Function: getConfig
     *  Get node configuration form.
     *
     *  Parameters:
     *    (String) node -  The name of the pubsub node.
     *    (Function) call_back - Receives config form.
     *
     *  Returns:
     *    Iq id
     */
  getConfig(node, call_back) {
    var that = this.connection;
    var iqid = that.getUniqueId("pubsubconfigurenode");

    var iq = Strophe.$iq({
      'from': this.jid,
      'to': this.service,
      'type': 'get',
      'id': iqid
    }).c('pubsub', {'xmlns': Strophe.NS['PUBSUB_OWNER']}).c(
        'configure', {node: node});

    that.addHandler(call_back, null, 'iq', null, iqid, null);
    that.send(iq.tree());

    return iqid;
  }

  /**
     *  Parameters:
     *    (Function) call_back - Receives subscriptions.
     *
     *  http://xmpp.org/extensions/tmp/xep-0060-1.13.html
     *  8.3 Request Default Node Configuration Options
     *
     *  Returns:
     *    Iq id
     */
  getDefaultNodeConfig(call_back) {
    var that = this.connection;
    var iqid = that.getUniqueId("pubsubdefaultnodeconfig");

    var iq = Strophe.$iq({
      'from': this.jid,
      'to': this.service,
      'type': 'get',
      'id': iqid
    }).c('pubsub', {'xmlns': Strophe.NS['PUBSUB_OWNER']}).c('default');

    that.addHandler(call_back, null, 'iq', null, iqid, null);
    that.send(iq.tree());

    return iqid;
  }

  /***Function
        Subscribe to a node in order to receive event items.
        Parameters:
        (String) node         - The name of the pubsub node.
        (Array) options       - The configuration options for the  node.
        (Function) event_cb   - Used to recieve subscription events.
        (Function) success    - callback function for successful node creation.
        (Function) error      - error callback function.
        (Boolean) barejid     - use barejid creation was sucessful.
        Returns:
        Iq id used to send subscription.
    */
  subscribe(node, options, event_cb, success, error, barejid) {
    var that = this.connection;
    var iqid = that.getUniqueId("subscribenode");

    var jid = this.jid;
    if (barejid) jid = Strophe.getBareJidFromJid(jid);

    var iq = Strophe.$iq({
      'from': this.jid,
      'to': this.service,
      'type': 'set',
      'id': iqid
    }).c('pubsub', {'xmlns': Strophe.NS['PUBSUB']}).c(
        'subscribe', {'node': node, 'jid': jid});
    if (options) {
      PubsubBuilder c = iq.up().c('options');

      c.form(Strophe.NS['PUBSUB_SUBSCRIBE_OPTIONS'], options);
    }

    //add the event handler to receive items
    var hand = that.addHandler(event_cb, null, 'message', null, null, null);
    this.storeHandler(node, hand);
    that.sendIQ(iq.tree(), success, error);
    return iqid;
  }

  /***Function
        Unsubscribe from a node.
        Parameters:
        (String) node       - The name of the pubsub node.
        (Function) success  - callback function for successful node creation.
        (Function) error    - error callback function.
    */
  unsubscribe(node, jid, subid, success, error) {
    var that = this.connection;
    var iqid = that.getUniqueId("pubsubunsubscribenode");

    var iq = Strophe.$iq({
      'from': this.jid,
      'to': this.service,
      'type': 'set',
      'id': iqid
    }).c('pubsub', {'xmlns': Strophe.NS['PUBSUB']}).c(
        'unsubscribe', {'node': node, 'jid': jid});
    if (subid) iq.attrs({subid: subid});

    that.sendIQ(iq.tree(), success, error);
    this.removeHandler(node);
    return iqid;
  }

  /***Function
    Publish and item to the given pubsub node.
    Parameters:
    (String) node -  The name of the pubsub node.
    (Array) items -  The list of items to be published.
    (Function) call_back - Used to determine if node
    creation was sucessful.
    */
  publish(node, items, callback) {
    String iqid = this.connection.getUniqueId("pubsubpublishnode");

    PubsubBuilder iq = Strophe.$iq({
      'from': this.jid,
      'to': this.service,
      'type': 'set',
      'id': iqid
    }).c('pubsub', {'xmlns': Strophe.NS['PUBSUB']}).c(
        'publish', {node: node, jid: this.jid});
    iq.list('item', items);

    this.connection.addHandler(callback, null, 'iq', null, iqid, null);
    this.connection.send(iq.tree());

    return iqid;
  }

  /*Function: items
    Used to retrieve the persistent items from the pubsub node.
    */
  items(node, success, error, timeout) {
    //ask for all items
    var iq = Strophe
        .$iq({'from': this.jid, 'to': this.service, 'type': 'get'}).c(
            'pubsub', {'xmlns': Strophe.NS['PUBSUB']}).c('items', {node: node});

    return this.connection.sendIQ(iq.tree(), success, error, timeout);
  }

  /** Function: getSubscriptions
     *  Get subscriptions of a JID.
     *
     *  Parameters:
     *    (Function) call_back - Receives subscriptions.
     *
     *  http://xmpp.org/extensions/tmp/xep-0060-1.13.html
     *  5.6 Retrieve Subscriptions
     *
     *  Returns:
     *    Iq id
     */
  getSubscriptions(call_back, timeout) {
    var that = this.connection;
    var iqid = that.getUniqueId("pubsubsubscriptions");

    var iq = Strophe.$iq({
      'from': this.jid,
      'to': this.service,
      'type': 'get',
      'id': iqid
    }).c('pubsub', {'xmlns': Strophe.NS['PUBSUB']}).c('subscriptions');

    that.addHandler(call_back, null, 'iq', null, iqid, null);
    that.send(iq.tree());

    return iqid;
  }

  /** Function: getNodeSubscriptions
     *  Get node subscriptions of a JID.
     *
     *  Parameters:
     *    (Function) call_back - Receives subscriptions.
     *
     *  http://xmpp.org/extensions/tmp/xep-0060-1.13.html
     *  5.6 Retrieve Subscriptions
     *
     *  Returns:
     *    Iq id
     */
  getNodeSubscriptions(node, call_back) {
    var that = this.connection;
    var iqid = that.getUniqueId("pubsubsubscriptions");

    var iq = Strophe.$iq({
      'from': this.jid,
      'to': this.service,
      'type': 'get',
      'id': iqid
    }).c('pubsub', {'xmlns': Strophe.NS['PUBSUB_OWNER']}).c(
        'subscriptions', {'node': node});

    that.addHandler(call_back, null, 'iq', null, iqid, null);
    that.send(iq.tree());

    return iqid;
  }

  /** Function: getSubOptions
     *  Get subscription options form.
     *
     *  Parameters:
     *    (String) node -  The name of the pubsub node.
     *    (String) subid - The subscription id (optional).
     *    (Function) call_back - Receives options form.
     *
     *  Returns:
     *    Iq id
     */
  getSubOptions(node, subid, call_back) {
    var that = this.connection;
    var iqid = that.getUniqueId("pubsubsuboptions");

    var iq = Strophe.$iq({
      'from': this.jid,
      'to': this.service,
      'type': 'get',
      'id': iqid
    }).c('pubsub', {'xmlns': Strophe.NS['PUBSUB']}).c(
        'options', {'node': node, 'jid': this.jid});
    if (subid) iq.attrs({subid: subid});

    that.addHandler(call_back, null, 'iq', null, iqid, null);
    that.send(iq.tree());

    return iqid;
  }

  /**
     *  Parameters:
     *    (String) node -  The name of the pubsub node.
     *    (Function) call_back - Receives subscriptions.
     *
     *  http://xmpp.org/extensions/tmp/xep-0060-1.13.html
     *  8.9 Manage Affiliations - 8.9.1.1 Request
     *
     *  Returns:
     *    Iq id
     */
  getAffiliations(node, [callback]) {
    String iqid = this.connection.getUniqueId("pubsubaffiliations");

    if (node is Function) {
      callback = node;
      node = null;
    }

    var attrs = {}, xmlns = {'xmlns': Strophe.NS['PUBSUB']};
    if (node != null) {
      attrs['node'] = node;
      xmlns = {'xmlns': Strophe.NS['PUBSUB_OWNER']};
    }

    var iq = Strophe
        .$iq({'from': this.jid, 'to': this.service, 'type': 'get', 'id': iqid})
        .c('pubsub', xmlns)
        .c('affiliations', attrs);

    this.connection.addHandler(callback, null, 'iq', null, iqid, null);
    this.connection.send(iq.tree());

    return iqid;
  }

  /**
     *  Parameters:
     *    (String) node -  The name of the pubsub node.
     *    (Function) call_back - Receives subscriptions.
     *
     *  http://xmpp.org/extensions/tmp/xep-0060-1.13.html
     *  8.9.2 Modify Affiliation - 8.9.2.1 Request
     *
     *  Returns:
     *    Iq id
     */
  setAffiliation(node, jid, affiliation, callback) {
    String iqid = this.connection.getUniqueId("pubsubaffiliations");

    var iq = Strophe.$iq({
      'from': this.jid,
      'to': this.service,
      'type': 'set',
      'id': iqid
    }).c('pubsub', {'xmlns': Strophe.NS['PUBSUB_OWNER']}).c('affiliations', {
      'node': node
    }).c('affiliation', {'jid': jid, 'affiliation': affiliation});

    this.connection.addHandler(callback, null, 'iq', null, iqid, null);
    this.connection.send(iq.tree());

    return iqid;
  }

  /** Function: publishAtom
     */
  publishAtom(node, atoms, callback) {
    if (atoms is! List) atoms = [atoms];

    var atom;
    List entries = [];
    for (int i = 0; i < atoms.length; i++) {
      atom = atoms[i];

      atom['updated'] = atom['updated'] ?? new DateTime.now().toIso8601String();
      if (atom['published'] && atom['published'].toIso8601String())
        atom['published'] = atom['published'].toIso8601String();

      entries.add({
        'data': (Strophe.$build("entry", {'xmlns': Strophe.NS['ATOM']})
                as PubsubBuilder)
            .children(atom)
            .tree(),
        'attrs': (atom.id ? {'id': atom.id} : {}),
      });
    }
    return this.publish(node, entries, callback);
  }
}
