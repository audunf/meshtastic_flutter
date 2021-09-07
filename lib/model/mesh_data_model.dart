

import 'package:flutter/cupertino.dart';
import 'package:meshtastic_flutter/model/mesh_position.dart';
import 'package:sqflite/sqflite.dart';
import 'mesh_my_node_info.dart';
import 'mesh_node.dart';
import 'mesh_user.dart';
import 'meshtastic_db.dart';


class MeshDataModel extends ChangeNotifier {
  MeshMyNodeInfo _myNodeInfo = MeshMyNodeInfo(0, 0, false, 0, 0, "NA", 0, 0, 0, 0, 0);
  final Map<String, MeshUser> _users = new Map(); // User.id is key
  final Map<int, MeshNode> _nodes = new Map(); // Node.id is key (nodeNum)
  final Map<int, MeshPosition> _positions = new Map(); // Node.id is key (nodeNum)

  /// Clear all data
  clearModel() {
    _myNodeInfo = MeshMyNodeInfo(0, 0, false, 0, 0, "NA", 0, 0, 0, 0, 0);
    _users.clear();
    _nodes.clear();
    notifyListeners();
  }

  ///
  MeshPosition? getPosition(int nodeNum) {
    if (!_positions.containsKey(nodeNum)) return null;
    else return _positions[nodeNum];
  }

  ///
  updatePosition(MeshPosition p) {
    _positions[p.nodeNum] = p;
    notifyListeners();
  }

  ///
  MeshUser? getUser(String userId) {
    if (!_users.containsKey(userId)) return null; 
    else return _users[userId];
  }

  ///
  updateUser(MeshUser u) {
    _users[u.userId] = u;
    notifyListeners();
  }

  ///
  MeshNode? getMeshNode(int nodeNum) {
    if (!_nodes.containsKey(nodeNum)) return null;
    else return _nodes[nodeNum];
  }

  ///
  updateMeshNode(MeshNode n) {
    _nodes[n.nodeNum] = n;
    notifyListeners();
  }

  ///
  Iterable<MeshNode> getMeshNodeIterable() {
    return _nodes.values;
  }
  
  ///
  MeshMyNodeInfo get myNodeInfo {
    return _myNodeInfo;
  }

  /// Return MeshNode for currently connected radio
  MeshNode? getMyMeshNode() {
    return _nodes[_myNodeInfo.nodeNum];
  }

  /// Return MeshPosition for currently connected radio
  MeshPosition? getMyPosition() {
    return _positions[_myNodeInfo.nodeNum];
  }

  /// Return MeshPosition for currently connected radio
  MeshUser? getMyUser() {
    MeshNode? mn = getMyMeshNode();
    if (mn == null) return null;
    return _users[mn.userId];
  }

  ///
  setMyNodeInfo(MeshMyNodeInfo n) {
    _myNodeInfo = n;
    notifyListeners();
  }

  ///
  load(int newBluetoothId) async {
    print("MeshDataModel::load");
    Database db = await MeshtasticDb.database;
    List<Map<String, Object?>> rLst = await db.rawQuery('SELECT * FROM my_node_info WHERE bluetooth_id=?;', [newBluetoothId]);
    for (var m in rLst) {
      _myNodeInfo = MeshMyNodeInfo.fromMap(m);
    }

    rLst = await db.rawQuery('SELECT * FROM node_info WHERE bluetooth_id=?;', [newBluetoothId]);
    for (var m in rLst) {
      MeshNode mn = MeshNode.fromMap(m);
      _nodes[mn.nodeNum] = mn;
    }

    rLst = await db.rawQuery('SELECT * FROM user WHERE bluetooth_id=?;', [newBluetoothId]);
    for (var m in rLst) {
      MeshUser mu = MeshUser.fromMap(m);
      _users[mu.userId] = mu;
    }

    rLst = await db.rawQuery('SELECT * FROM position WHERE bluetooth_id=?;', [newBluetoothId]);
    for (var m in rLst) {
      MeshPosition mp = MeshPosition.fromMap(m);
      _positions[mp.nodeNum] = mp;
    }

    notifyListeners();
  }

  ///
  save() async {
    return MeshtasticDb.database.then((db) {
      return db.transaction((txn) async {
        var batch = txn.batch();
        batch.delete('user', where: 'bluetooth_id = ?', whereArgs: [_myNodeInfo.bluetoothId]);
        batch.delete('position', where: 'bluetooth_id = ?', whereArgs: [_myNodeInfo.bluetoothId]);
        batch.delete('node_info', where: 'bluetooth_id = ?', whereArgs: [_myNodeInfo.bluetoothId]);
        batch.delete('my_node_info', where: 'bluetooth_id = ?', whereArgs: [_myNodeInfo.bluetoothId]);

        batch.insert('my_node_info', _myNodeInfo.toMap());
        _nodes.forEach((id, e) {
          batch.insert('node', e.toMap());
        });
        _users.forEach((id, e) {
          batch.insert('user', e.toMap());
        });
        _positions.forEach((id, e) {
          batch.insert('position', e.toMap());
        });
        return batch.commit(noResult: true);
      });
    }).catchError((e, s) {
      print('MeshDataModel::save - exception $e $s');
    });
  }

}