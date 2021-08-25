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

class FromRadioCommandQueue extends MeshtasticDb {
  FromRadioCommandQueue._internal();
  static final FromRadioCommandQueue _singleton = new FromRadioCommandQueue._internal();
  static FromRadioCommandQueue get instance => _singleton;


}