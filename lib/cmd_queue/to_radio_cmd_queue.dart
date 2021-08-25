import 'meshtastic_db.dart';

/*
There needs to be:
1. A ToRadio command queue. Any actions get added to this queue. It's sent whenever the phone connects.
2. A FromRadio queue. This is the history of all that happened with a particular device.
- Both of these need an SQLite DB, with NodeId as key. On connecting to a certain node, use that as key for the tables, and load.
- When no node is connected, assume the previous nodeId.
- On changing node, load the items from that node.
- Once done with the queue, disconnect BT
 */
class ToRadioCommandQueue extends MeshtasticDb {
  ToRadioCommandQueue._internal();
  static final ToRadioCommandQueue _singleton = new ToRadioCommandQueue._internal();
  static ToRadioCommandQueue get instance => _singleton;

  /*
  ///
  Future<void> save(StoryListType listType, List<int> lst) async {
    print('ListDatabase save ${listType.toString()} -- ${lst.length}');
    if (lst == null || lst.length <= 0) {
      return Future.wait([]);
    }

    return database.then((db) {
      return db.execute('REPLACE INTO $listTableName VALUES(?,?);', [describeEnum(listType), lst.join(',')]);
    }).catchError((e, s) {
      print('ArticleDatabase:save - exception $e $s');
    });
  }

  ///
  Future<List<int>> load(StoryListType listType) async {
    return database.then((db) {
      return db.query(listTableName, where: 'list_name = ?', whereArgs: [describeEnum(listType)]);
    }).then((List<Map> r) {
      if (r == null || r.length <= 0) {
        return List<int>();
      }
      String s = r.first['list_data'];
      if (s == null || s.length <= 0) {
        return List<int>();
      }
      return s.split(',').map((x) {
        return int.parse(x);
      }).toList();
    });
  }
   */
}
