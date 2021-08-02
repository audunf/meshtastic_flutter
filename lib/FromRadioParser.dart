import 'package:meshtastic_flutter/proto-autogen/admin.pb.dart';
import 'package:meshtastic_flutter/proto-autogen/mesh.pb.dart';
import 'package:meshtastic_flutter/proto-autogen/portnums.pb.dart';

class FromRadioParser {

  handleFromRadio(dataBuffer) {
    FromRadio fr = FromRadio.fromBuffer(dataBuffer);

    switch(fr.whichPayloadVariant()) {
      case FromRadio_PayloadVariant.packet:
        handleMeshPacket(fr.packet);
        break;
      case FromRadio_PayloadVariant.logRecord:
        handleLogRecord(fr.logRecord);
        break;
      case FromRadio_PayloadVariant.myInfo:
        handleMyNodeInfo(fr.myInfo);
        break;
      case FromRadio_PayloadVariant.nodeInfo:
        handleNodeInfo(fr.nodeInfo);
        break;
      case FromRadio_PayloadVariant.configCompleteId:
        print("** configCompleteId " + fr.configCompleteId.toString());
        break;
      case FromRadio_PayloadVariant.rebooted:
        print("** rebooted " + fr.rebooted.toString());
        break;
      case FromRadio_PayloadVariant.notSet:
        print("** notSet");
        break;
      default:
        print("** DEFAULT: " + fr.toDebugString());
        break;
    }
  }

  handleNodeInfo(NodeInfo ni) {
    print("** nodeInfo " + ni.toString());
  }

  handleMyNodeInfo(MyNodeInfo mni) {
    print("** myNodeInfo " + mni.toString());
  }

  handleLogRecord(LogRecord lr) {
    print("** logRecord " + lr.toString());
  }

  handleMeshPacket(MeshPacket mp) {
    print("** handleMeshPacket ");

    switch(mp.whichPayloadVariant()) {
      case MeshPacket_PayloadVariant.decoded:
        handleDataPayload(mp.decoded);
        break;
      case MeshPacket_PayloadVariant.encrypted:
        handleEncryptedPayload(mp.encrypted);
        break;
    }
  }

  handleDataPayload(Data d) {
    switch(d.portnum) {
      case PortNum.TEXT_MESSAGE_APP:
        handleTextMessagePortNum(d.payload);
        break;
      case PortNum.REMOTE_HARDWARE_APP:
        break;
      case PortNum.POSITION_APP:
        handlePositionPortNum(d.payload);
        break;
      case PortNum.NODEINFO_APP:
        handleNodeInfoPortNum(d.payload);
        break;
      case PortNum.ROUTING_APP:
        handleRoutingPortNum(d.payload);
        break;
      case PortNum.ADMIN_APP:
        handleAdminPortNum(d.payload);
        break;
      case PortNum.REPLY_APP:
        print("PortNum.REPLY_APP");
        break;
      case PortNum.IP_TUNNEL_APP:
        print("PortNum.IP_TUNNEL_APP");
        break;
      case PortNum.SERIAL_APP:
        print("PortNum.SERIAL_APP");
        break;
      case PortNum.STORE_FORWARD_APP:
        print("PortNum.STORE_FORWARD_APP");
        break;
      case PortNum.RANGE_TEST_APP:
        print("PortNum.RANGE_TEST_APP");
        break;
      case PortNum.ENVIRONMENTAL_MEASUREMENT_APP:
        print("PortNum.ENVIRONMENTAL_MEASUREMENT_APP");
        break;
      case PortNum.PRIVATE_APP:
        print("PortNum.PRIVATE_APP");
        break;
      case PortNum.ATAK_FORWARDER:
        print("PortNum.ATAK_FORWARDER");
        break;
      case PortNum.UNKNOWN_APP:
        print("PortNum.UNKNOWN_APP - ignoring");
        break;
      default:
        print("PortNum - DEFAULT - should not happen");
        break;
    }
  }

  handleEncryptedPayload(List<int> bytes) {
    print("*** handleEncryptedPayload - NOT HANDLED - FIXME");
  }

  handleAdminPortNum(buf) {
    AdminMessage am = AdminMessage.fromBuffer(buf);
    print("*** handleAdminPortNum: " + am.toString());
  }

  handlePositionPortNum(buf) {
    Position p = Position.fromBuffer(buf);
    print("*** handlePositionPortNum: " + p.toString());
  }

  handleRoutingPortNum(buf) {
    Routing r = Routing.fromBuffer(buf);
    print("*** handleRoutingPortNum: " + r.toString());
  }

  handleNodeInfoPortNum(buf) {
    User u = User.fromBuffer(buf);
    print("*** handleNodeInfoPortNum: " + u.toString());
  }

  handleTextMessagePortNum(buf) {
    print("*** TEXT MESSAGE: " + buf.toString());
  }
}