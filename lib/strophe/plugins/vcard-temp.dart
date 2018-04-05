import 'package:localsocialnetwork/strophe/core.dart';
import 'package:localsocialnetwork/strophe/enums.dart';
import 'package:localsocialnetwork/strophe/plugins/plugins.dart';
import 'package:xml/xml.dart' as xml;

class VCardTemp extends PluginClass {
  StanzaBuilder _buildIq(String type, String jid, [xml.XmlElement vCardEl]) {
    StanzaBuilder iq =
        Strophe.$iq(jid != null ? {'type': type, 'to': jid} : {'type': type});
    iq.c("vCard", {'xmlns': Strophe.NS['VCARD']});
    if (vCardEl != null) {
      iq.cnode(vCardEl);
    }
    return iq;
  }

  init(StropheConnection conn) {
    this.connection = conn;
    return Strophe.addNamespace('VCARD', 'vcard-temp');
  }

  /* Function
         * Retrieve a vCard for a JID/Entity
         * Parameters:
         * (Function) handler_cb - The callback function used to handle the request.
         * (String) jid - optional - The name of the entity to request the vCard
         *     If no jid is given, this function retrieves the current user's vcard.
         * */
  get(Function handlerCb, String jid, Function errorCb) {
    var iq = _buildIq("get", jid);
    return this.connection.sendIQ(iq.tree(), handlerCb, errorCb);
  }

  /* Function
         *  Set an entity's vCard.
         */
  set(Function handlerCb, xml.XmlElement vCardEl, String jid,
      Function errorCb) {
    StanzaBuilder iq = _buildIq("set", jid, vCardEl);
    return this.connection.sendIQ(iq.tree(), handlerCb, errorCb);
  }
}
