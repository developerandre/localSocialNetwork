import 'package:localsocialnetwork/strophe/core.dart';
import 'package:localsocialnetwork/strophe/enums.dart';
import 'package:localsocialnetwork/strophe/plugins/plugins.dart';
import 'package:xml/xml.dart' as xml;

/**
 * This plugin is distributed under the terms of the MIT licence.
 * Please see the LICENCE file for details.
 * Copyright (c) Markus Kohlhase, 2011
 */

/**
* File: strophe.private.js
* A Strophe plugin for XMPP Private XML Storage ( http://xmpp.org/extensions/xep-0049.html )
*/
class PrivateStorage extends PluginClass {
  // called by the Strophe.Connection constructor

  init(StropheConnection conn) {
    this.connection = conn;
    Strophe.addNamespace('PRIVATE', "jabber:iq:private");
  }

  /**
   * Function: set
   *
   * Parameters:
   * (String) tag - the tag name
   * (String) ns  - the namespace
   * (XML) data   - the data you want to save
   * (Function) success - Callback function on success
   * (Function) error - Callback function on error
   */

  set(String tag, String ns, data, Function success, Function error) {
    String id = this.connection.getUniqueId('saveXML');

    StanzaBuilder iq = Strophe.$iq({'type': 'set', 'id': id}).c(
        'query', {'xmlns': Strophe.NS['PRIVATE']}).c(tag, {'xmlns': ns});

    var d = this._transformData(data);

    if (d) {
      iq.cnode(d);
    }

    this.connection.sendIQ(iq.tree(), success, error);
  }

  /**
   * Function: get
   *
   * Parameters:
   * (String) tag - the tag name
   * (String) ns  - the namespace
   * (Function) success - Callback function on success
   * (Function) error - Callback function on error
   */

  get(String tag, String ns, Function success, [Function error]) {
    String id = this.connection.getUniqueId('loadXML');

    StanzaBuilder iq = Strophe.$iq({'type': 'get', 'id': id}).c(
        'query', {'xmlns': Strophe.NS['PRIVATE']}).c(tag, {'xmlns': ns});

    this.connection.sendIQ(iq.tree(), (xml.XmlElement iq) {
      xml.XmlNode data = iq;

      for (int i = 0; i < 3; i++) {
        data = data.children[0];
        if (data == null) {
          break;
        }
      }

      success(data, iq);
    }, error);
  }

  /**
   * PrivateFunction: _transformData
   */
  _transformData(c) {
    switch (c.runtimeType.toString()) {
      case "num":
      case "bool":
        return Strophe.xmlTextNode(c + '');
      case "String":
        var dom = this._textToXml(c);

        if (dom != null) {
          return dom;
        } else {
          return Strophe.xmlTextNode(c + '');
        }
        break;
      default:
        if (this._isNode(c) || this._isElement(c)) {
          return c;
        }
    }
    return null;
  }

  /**
   * PrivateFunction: _textToXml
   *
   * Parameters:
   * (String) text  - XML String
   *
   * Returns:
   * (Object) dom - DOM Object
   */

  xml.XmlElement _textToXml(String text) {
    return xml.parse(text).rootElement;
  }
  /**
   * PrivateFunction: _isNode
   *
   * Parameters:
   * ( Object ) obj - The object to test
   *
   * Returns:
   * True if it is a DOM node
   */

  bool _isNode(obj) {
    return obj is xml.XmlNode;
  }

  /**
   * PrivateFunction: _isElement
   *
   * Parameters:
   * ( Object ) obj - The object to test
   *
   * Returns:
   * True if it is a DOM element.
   */

  bool _isElement(obj) {
    return obj is xml.XmlElement;
  }
}
