
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

class TabDefinition {
  final int index;
  final String title;
  final IconData icon;
  final MaterialColor color;
  final HashMap<String, Function> screens = new HashMap<String, Function>();

  TabDefinition(this.index, this.title, this.icon, this.color, List<Tuple2<String, Function>> screenList) {
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
