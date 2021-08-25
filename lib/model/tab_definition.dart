
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

/// Keeps track of tab definitions. Passed to actual tabs for configuration.
/// A tab can have several screens/pages "under" it. For example, the "Settings" tab has sub-screens
/// for choosing BT devices, settings user name, etc.
class TabDefinition {
  final int index;
  final String title;
  final IconData icon;
  final Color appbarColor;
  final Color backgroundColor;
  final HashMap<String, Function> screens = new HashMap<String, Function>();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  TabDefinition(this.index, this.title, this.icon, this.appbarColor, this.backgroundColor, List<Tuple2<String, Function>> screenList) {
    for (var e in screenList) {
      screens.putIfAbsent(e.item1, () => e.item2);
    }
  }

  Widget createDefaultScreen(TabDefinition tabDefinition) {
    Function? f = screens["/"];
    if (f != null) {
     return f(tabDefinition);
    } else {
      throw Exception("Default route '/' not found");
    }
  }

  Widget createScreen(String? routeParam, TabDefinition tabDefinition) {
    Function? f = screens[routeParam];
    if (f != null) {
      return f(tabDefinition);
    } else {
      throw Exception("The route $routeParam not found when creating screen.");
    }
  }
}
