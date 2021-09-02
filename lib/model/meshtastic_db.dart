import 'dart:async';
import 'dart:io';
import 'package:async/async.dart';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

///
///
///
class MeshtasticDb {
  // names used for database
  static final _initDB = AsyncMemoizer<Database>();
  static final String mainDatabaseName = 'meshtastic_flutter.db';

  MeshtasticDb();

  ///
  static Future<Database> get database => _initDB.runOnce(() async => await _openDB());

  ///
  static Future<Database> _openDB() async {
    // The path_provider plugin gets the right directory for Android or iOS.
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, mainDatabaseName);
    print("***** opening DB: $path");
    Sqflite.setDebugModeOn(false); // SQL DEBUG MODE SWITCH !!!

    return await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {

          // bluetooth ID: 08:3A:F2:44:BB:0A
          await db.execute('''           
            CREATE TABLE IF NOT EXISTS radio_command (
              direction       INTEGER NOT NULL,
              bluetooth_id    INTEGER NOT NULL,
              epoch_ms        INTEGER NOT NULL,
              checksum        INTEGER NOT NULL, 
              acknowledged    INTEGER NOT NULL,
              stored          INTEGER NOT NULL,
              dirty           INTEGER NOT NULL,
              payload_variant INTEGER NOT NULL,
              payload         BLOB DEFAULT NULL,
              PRIMARY KEY (bluetooth_id, direction, epoch_ms, checksum)
            ); ''');

          await db.execute('''
            CREATE INDEX IF NOT EXISTS radio_cmd_index ON radio_command(bluetooth_id, direction, dirty);           
            ''');
        });
  }


  ///
  static Future<void> close() async {
    var db = await database;
    await db.close();
  }
}
