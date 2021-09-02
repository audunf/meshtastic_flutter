import 'dart:convert' show utf8;
import 'package:meshtastic_flutter/bluetooth/ble_data_streams.dart';
import 'package:meshtastic_flutter/model/mesh_data_model.dart';
import 'package:meshtastic_flutter/model/settings_model.dart';
import 'package:meshtastic_flutter/proto-autogen/admin.pb.dart';
import 'package:meshtastic_flutter/proto-autogen/mesh.pb.dart';
import 'package:meshtastic_flutter/proto-autogen/portnums.pbenum.dart';

/// TODO
/// Hook up "Region" to settings
/// Hook up "User name" to settings
/// Write User name and region back to device on change.

/// Listens to the FromRadio data stream. Has references to the 'SettingsModel' and 'MeshDataModel'
/// Updates the data models based on incoming FromRadio packets
class AppFromRadioHandler {
  final MeshDataModel meshDataModel;
  final SettingsModel settingsModel;
  final BleDataStreams bleDataStreams;

  /// get text message payload as String
  static String getTextMessageUtf8Payload(FromRadio fr) {
    if (fr.whichPayloadVariant() == FromRadio_PayloadVariant.packet &&
        fr.packet.whichPayloadVariant() == MeshPacket_PayloadVariant.decoded &&
        fr.packet.decoded.portnum == PortNum.TEXT_MESSAGE_APP && fr.packet.decoded.payload.length > 0)
    {
      return utf8.decode(fr.packet.decoded.payload);
    }
    return "";
  }

  AppFromRadioHandler({required this.bleDataStreams, required this.settingsModel, required this.meshDataModel}) {
    bleDataStreams.fromRadioStream.listen(_handleFromRadio);
  }

  _handleFromRadio(FromRadio fr) {
    switch (fr.whichPayloadVariant()) {
      case FromRadio_PayloadVariant.packet:
        return _handleMeshPacket(fr.packet);
      case FromRadio_PayloadVariant.logRecord:
        return _handleLogRecord(fr.logRecord);
      case FromRadio_PayloadVariant.myInfo:
        return _handleMyNodeInfo(fr.myInfo);
      case FromRadio_PayloadVariant.nodeInfo:
        return _handleNodeInfo(fr.nodeInfo);
      case FromRadio_PayloadVariant.configCompleteId:
        print("** configCompleteId " + fr.configCompleteId.toString());
        return false;
      case FromRadio_PayloadVariant.rebooted:
        print("** rebooted " + fr.rebooted.toString());
        return false;
      case FromRadio_PayloadVariant.notSet:
        print("** notSet");
        return false;
      default:
        print("** DEFAULT: " + fr.toDebugString());
        return false;
    }
  }

  // MyNodeInfo holds info about the current node connected via BT
  _handleMyNodeInfo(MyNodeInfo mni) {
    print("** myNodeInfo " + mni.toString());
    meshDataModel.setMyNodeInfo(mni);
    settingsModel.setMyNodeNum(mni.myNodeNum);
    return mni;
  }

  _handleNodeInfo(NodeInfo ni) {
    print("** nodeInfo " + ni.toString());
    meshDataModel.updateNodeInfo(ni);

    if (ni.num == meshDataModel.myNodeInfo.myNodeNum) {
      // if this NodeInfo is about our local node
      settingsModel.setUserLongName(ni.user.longName);
      settingsModel.setUserShortName(ni.user.shortName);
    } else {
      // this NodeInfo is about another node in the mesh
    }

    return ni;
  }

  _handleLogRecord(LogRecord lr) {
    print("** logRecord " + lr.toString());
    return lr;
  }

  _handleMeshPacket(MeshPacket mp) {
    print("** handleMeshPacket ");

    // mp.from
    // mp.to
    // mp.channel
    // mp.rxRssi // rssi of received packet. Only sent to phone for dispay purposes.

    switch (mp.whichPayloadVariant()) {
      case MeshPacket_PayloadVariant.decoded:
        return _handleDataPayload(mp.decoded);
      case MeshPacket_PayloadVariant.encrypted:
        return _handleEncryptedPayload(mp.encrypted);
      default:
        print("-> unknown packet payload variant " + mp.whichPayloadVariant().toString());
        break;
    }
  }

  _handleDataPayload(Data d) {
    switch (d.portnum) {
      case PortNum.TEXT_MESSAGE_APP:
        return _handleTextMessagePortNum(d.payload);
      case PortNum.REMOTE_HARDWARE_APP:
        print("PortNum.REMOTE_HARDWARE_APP");
        return false;
      case PortNum.POSITION_APP:
        return _handlePositionPortNum(d.payload);
      case PortNum.NODEINFO_APP:
        return _handleNodeInfoPortNum(d.payload);
      case PortNum.ROUTING_APP:
        return _handleRoutingPortNum(d.payload);
      case PortNum.ADMIN_APP:
        return _handleAdminPortNum(d.payload);
      case PortNum.REPLY_APP:
        print("PortNum.REPLY_APP");
        return false;
      case PortNum.IP_TUNNEL_APP:
        print("PortNum.IP_TUNNEL_APP");
        return false;
      case PortNum.SERIAL_APP:
        print("PortNum.SERIAL_APP");
        return false;
      case PortNum.STORE_FORWARD_APP:
        print("PortNum.STORE_FORWARD_APP");
        return false;
      case PortNum.RANGE_TEST_APP:
        print("PortNum.RANGE_TEST_APP");
        return false;
      case PortNum.ENVIRONMENTAL_MEASUREMENT_APP:
        print("PortNum.ENVIRONMENTAL_MEASUREMENT_APP");
        return false;
      case PortNum.PRIVATE_APP:
        print("PortNum.PRIVATE_APP");
        return false;
      case PortNum.ATAK_FORWARDER:
        print("PortNum.ATAK_FORWARDER");
        return false;
      case PortNum.UNKNOWN_APP:
        print("PortNum.UNKNOWN_APP - ignoring");
        return false;
      default:
        print("PortNum - DEFAULT - should not happen");
        return false;
    }
  }

  _handleEncryptedPayload(List<int> bytes) {
    print("*** handleEncryptedPayload - NOT HANDLED - FIXME");
    return false;
  }

  _handleAdminPortNum(buf) {
    AdminMessage am = AdminMessage.fromBuffer(buf);
    print("*** handleAdminPortNum: " + am.toString());
    switch (am.whichVariant()) {
      case AdminMessage_Variant.setRadio:
        break;
      case AdminMessage_Variant.setOwner:
        break;
      case AdminMessage_Variant.setChannel:
        break;
      case AdminMessage_Variant.getRadioRequest:
        break;
      case AdminMessage_Variant.getRadioResponse:
        break;
      case AdminMessage_Variant.getChannelRequest:
        break;
      case AdminMessage_Variant.getChannelResponse:
        break;
      case AdminMessage_Variant.confirmSetChannel:
        break;
      case AdminMessage_Variant.confirmSetRadio:
        break;
      case AdminMessage_Variant.exitSimulator:
        break;
      case AdminMessage_Variant.rebootSeconds:
        break;
      case AdminMessage_Variant.notSet:
        break;
      default:
        break;
    }
    return am;
  }

  _handlePositionPortNum(buf) {
    Position p = Position.fromBuffer(buf);
    print("*** handlePositionPortNum: " + p.toString());
    // update POSITION of the local node!
    /*
    ** handlePositionPortNum: latitudeI: 599667403
I/flutter (19407): longitudeI: 106456274
I/flutter (19407): altitude: 247
I/flutter (19407): batteryLevel: 69
I/flutter (19407): time: 1629368767
     */
    return p;
  }

  _handleRoutingPortNum(buf) {
    Routing r = Routing.fromBuffer(buf);
    print("*** handleRoutingPortNum: " + r.toString());
    return r;
  }

  _handleNodeInfoPortNum(buf) {
    User u = User.fromBuffer(buf);
    print("*** handleNodeInfoPortNum: " + u.toString());
    return u;
  }

  _handleTextMessagePortNum(buf) {
    print("*** TEXT MESSAGE: " + buf.toString());
    return false;
  }
}
