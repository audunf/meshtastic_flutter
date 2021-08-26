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


  ///
  Future<Database?> get database async {
    if (_database != null)
      return _database;

    // if _database is null -> instantiate it
    _database = await _initDBMemoizer.runOnce(() async {
      return await _openDB();
    });

    if (_database == null) {
      throw Exception("Unable to initialize/open database ");
    }

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

          // bluetooth ID: 08:3A:F2:44:BB:0A
          await db.execute('''           
            CREATE TABLE IF NOT EXISTS radio_command (
              direction    INTEGER NOT NULL,
              bluetooth_id INTEGER NOT NULL
              epoch_ms     INTEGER NOT NULL,
              checksum     INTEGER NOT NULL, 
              acknowledged INTEGER NOT NULL,
              stored       INTEGER NOT NULL,
              dirty        INTEGER NOT NULL,
              payload      BLOB DEFAULT NULL,
              PRIMARY KEY (direction, bluetooth_id, epoch_ms)
            ); ''');

          await db.execute('''
            CREATE INDEX radio_cmd_checksum_index ON to_radio(checksum);
            CREATE INDEX radio_cmd_index ON to_radio(bluetooth_id, direction, dirty);           
            ''');
        });
  }


  ///
  Future close() async {
    var db = await database;
    await db?.close();
  }
}
