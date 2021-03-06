import 'package:localsocialnetwork/strophe/core.dart';
import 'package:localsocialnetwork/strophe/enums.dart';
import 'package:localsocialnetwork/strophe/plugins/plugins.dart';
import 'package:localsocialnetwork/strophe/plugins/pubsub.dart';

class PepPlugin extends PluginClass {
  init(StropheConnection c) {
    this.connection = c;
    if (this.connection.caps == null) {
      throw {'error': "caps plugin required!"};
    }
    if (this.connection.pubsub == null) {
      throw {'error': "pubsub plugin required!"};
    }
  }

  subscribe(String node, Function handler) {
    this.connection.caps.addFeature(node);
    this.connection.caps.addFeature("" + node + "+notify");
    this.connection.addHandler(
        handler, Strophe.NS['PUBSUB_EVENT'], "message", null, null, null);
    return this.connection.caps.sendPres();
  }

  unsubscribe(String node) {
    this.connection.caps.removeFeature(node);
    this.connection.caps.removeFeature("" + node + "+notify");
    return this.connection.caps.sendPres();
  }

  String publish(
      String node, List<Map<String, dynamic>> items, Function callback) {
    String iqid = this.connection.getUniqueId("pubsubpublishnode");
    this.connection.addHandler(callback, null, 'iq', null, iqid, null);
    PubsubBuilder c = new PubsubBuilder(
            'iq', {'from': this.connection.jid, 'type': 'set', 'id': iqid})
        .c('pubsub', {'xmlns': Strophe.NS['PUBSUB']}).c(
            'publish', {'node': node, 'jid': this.connection.jid});
    this.connection.send(c.list('item', items).tree());
    return iqid;
  }
}
