import 'dart:async';
import 'dart:io';
import 'package:async/async.dart';
import 'package:flutter/foundation.dart';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

///
///
///
class MeshtasticDb {
  // names used for database
  final String mainDatabaseName = 'meshtastic_flutter.db';

  static Database? _database;
  final _initDBMemoizer = AsyncMemoizer<Database>();

  MeshtasticDb();

  Future<Database?> get database async {
    if (_database != null)
      return _database;

    // if _database is null -> instantiate it
    _database = await _initDBMemoizer.runOnce(() async {
      return await _openDB();
    });

    return _database;
  }

  ///
  Future<Database> _openDB() async {
    // The path_provider plugin gets the right directory for Android or iOS.
    Directory documentsDirectory = await getApplicationDocumentsDirectory();

    String path = join(documentsDirectory.path, mainDatabaseName);

    print("opening DB: $path");

    Sqflite.setDebugModeOn(false); // SQL DEBUG MODE SWITCH !!!

    return await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {

          // time, nodeId, blob with ToRadio data
          await db.execute('''           
            CREATE TABLE to_radio (
              epoch_ms INTEGER NOT NULL PRIMARY KEY ON CONFLICT REPLACE,
              node_num INTEGER NOT NULL,     
              payload BLOB DEFAULT NULL
            ); ''');

          await db.execute('''           
            CREATE TABLE from_radio (
              epoch_ms INTEGER NOT NULL PRIMARY KEY ON CONFLICT REPLACE,
              node_num INTEGER NOT NULL,     
              payload BLOB DEFAULT NULL
            ); ''');

          await db.execute('''
            CREATE INDEX to_radio_index ON to_radio(epoch_ms, node_num);
            CREATE INDEX from_radio_index ON from_radio(epoch_ms, node_num);
            ''');
        });
  }

  ///
  Future close() async {
    var db = await database;
    await db?.close();
  }
}
