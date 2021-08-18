

import 'package:flutter/cupertino.dart';
import 'package:meshtastic_flutter/proto-autogen/mesh.pb.dart';

class MeshDataModel extends ChangeNotifier {
  MyNodeInfo _myNodeInfo = MyNodeInfo().createEmptyInstance();
  final Map<String, User> _userList = new Map(); // User.id is key
  final Map<int, NodeInfo> _nodes = new Map(); // Node.id is key

  User? getUser(int userId) {
    return _userList[userId];
  }

  Iterable<NodeInfo> getNodeInfoIterable() {
    return _nodes.values;
  }

  NodeInfo? getNodeInfo(int nodeNum) {
    return _nodes[nodeNum];
  }

  updateNodeInfo(NodeInfo n) {
    _nodes[n.num] = n;
    if (n.user.id.isNotEmpty) {
      _userList[n.user.id] = n.user;
    }
    notifyListeners();
  }

  MyNodeInfo get myNodeInfo {
    return _myNodeInfo;
  }

  setMyNodeInfo(MyNodeInfo n) {
    _myNodeInfo = n;
    notifyListeners();
  }
}