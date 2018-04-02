import 'package:localsocialnetwork/strophe/enums.dart';

abstract class PluginClass {
  StropheConnection connection;
  Function statusChanged;
  PluginClass();
  init(StropheConnection conn);
}
