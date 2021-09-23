import 'dart:async';
import 'dart:io';
import 'package:async/async.dart';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

///
///
///
class MeshDatabase {
  // names used for database
  static final _initDB = AsyncMemoizer<Database>();
  static final String mainDatabaseName = 'meshtastic_flutter.db';

  MeshDatabase();

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

          // all packets are tied to a bluetoothId (MAC encoded as int) in order for the app to be able to work
          // with several distinct radios

          // MeshPacket
          await db.execute('''           
            CREATE TABLE IF NOT EXISTS mesh_data_packet (
              bluetooth_id       INTEGER NOT NULL,
              direction          INTEGER NOT NULL,
              payload_variant    INTEGER NOT NULL,
              checksum           INTEGER NOT NULL,
                                          
              packet_id          INTEGER NOT NULL,
              from_node_num      INTEGER NOT NULL,
              to_node_num        INTEGER NOT NULL,
              channel            INTEGER NOT NULL,
              rx_time_epoch_sec  INTEGER NOT NULL,
              rx_snr             REAL NOT NULL,
              hop_limit          INTEGER DEFAULT 3 NOT NULL,
              want_ack           INTEGER DEFAULT 0 NOT NULL,
              priority           INTEGER DEFAULT 64 NOT NULL,
              rx_rssi            INTEGER DEFAULT 0 NOT NULL,
              acknowledged       INTEGER DEFAULT 0 NOT NULL,
              payload            BLOB DEFAULT NULL,
              PRIMARY KEY (bluetooth_id, rx_time_epoch_sec, packet_id, from_node_num, to_node_num, channel, checksum)
            ); ''');

          await db.execute('''
            CREATE INDEX IF NOT EXISTS mesh_data_packet_dir_idx ON mesh_data_packet(bluetooth_id, direction);           
            ''');

          // NodeInfo.
          // Node can have 1x position (Reference from Position to the node_num)
          // User is a reference from NodeInfo *to* the User table (Same 'user' can exist on several different nodes)
          await db.execute('''           
            CREATE TABLE IF NOT EXISTS node_info (
              bluetooth_id          INTEGER NOT NULL,
              node_num              INTEGER NOT NULL,
              user_id               VARCHAR(100) NOT NULL,
              snr                   REAL NOT NULL,
              last_heard_epoch_sec  INTEGER NOT NULL,
              PRIMARY KEY (bluetooth_id, node_num)
            ); ''');

          // Position
          await db.execute('''           
            CREATE TABLE IF NOT EXISTS position (
              bluetooth_id         INTEGER NOT NULL,
              node_num             INTEGER NOT NULL,
              latitude             REAL NOT NULL,
              longitude            REAL NOT NULL,
              altitude             INTEGER NOT NULL,
              battery_level        INTEGER NOT NULL, 
              timestamp_epoch_sec  INTEGER NOT NULL,      
              PRIMARY KEY (bluetooth_id, node_num)
            ); ''');

          // MyNodeInfo
          await db.execute('''           
            CREATE TABLE IF NOT EXISTS my_node_info (
              bluetooth_id     INTEGER NOT NULL,
              node_num         INTEGER NOT NULL,
              has_gps          INTEGER NOT NULL,
              num_bands        INTEGER NOT NULL,
              max_channels     INTEGER NOT NULL,
              firmware_version VARCHAR(20) NOT NULL,
              error_code       INTEGER DEFAULT 0 NOT NULL,
              error_addr       INTEGER DEFAULT 0 NOT NULL,
              reboot_count     INTEGER DEFAULT 0 NOT NULL,
              msg_timeout_msec INTEGER DEFAULT 0 NOT NULL,
              min_app_version  INTEGER DEFAULT 0 NOT NULL,
              PRIMARY KEY (bluetooth_id)
            ); ''');

          // User
          await db.execute('''           
            CREATE TABLE IF NOT EXISTS user (
              bluetooth_id    INTEGER NOT NULL,
              user_id         VARCHAR(100) NOT NULL,
              long_name       VARCHAR(255) NOT NULL,
              short_name      VARCHAR(10) NOT NULL,
              mac_addr        BLOB NOT NULL,
              hw_model        INTEGER NOT NULL,
              is_licensed     INTEGER DEFAULT 0 NOT NULL,
              PRIMARY KEY (bluetooth_id, user_id)
            ); ''');

        });
  }


  ///
  static Future<void> close() async {
    var db = await database;
    await db.close();
  }
}
