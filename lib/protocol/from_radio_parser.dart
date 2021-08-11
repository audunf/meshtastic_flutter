import 'package:meshtastic_flutter/proto-autogen/admin.pb.dart';
import 'package:meshtastic_flutter/proto-autogen/mesh.pb.dart';
import 'package:meshtastic_flutter/proto-autogen/portnums.pb.dart';

class FromRadioParser {
  FromRadioParser();

  handleFromRadioBuffer(List<int> dataBuffer) {
    FromRadio fr = FromRadio.fromBuffer(dataBuffer);
  }

  handleFromRadio(FromRadio fr) {
    switch(fr.whichPayloadVariant()) {
      case FromRadio_PayloadVariant.packet:
        return handleMeshPacket(fr.packet);
      case FromRadio_PayloadVariant.logRecord:
        return handleLogRecord(fr.logRecord);
      case FromRadio_PayloadVariant.myInfo:
        return handleMyNodeInfo(fr.myInfo);
      case FromRadio_PayloadVariant.nodeInfo:
        return handleNodeInfo(fr.nodeInfo);
      case FromRadio_PayloadVariant.configCompleteId:
        print("** configCompleteId " + fr.configCompleteId.toString());
        return;
      case FromRadio_PayloadVariant.rebooted:
        print("** rebooted " + fr.rebooted.toString());
        return;
      case FromRadio_PayloadVariant.notSet:
        print("** notSet");
        return false;
      default:
        print("** DEFAULT: " + fr.toDebugString());
        return false;
    }
  }

  handleNodeInfo(NodeInfo ni) {
    print("** nodeInfo " + ni.toString());
    return ni;
  }

  handleMyNodeInfo(MyNodeInfo mni) {
    print("** myNodeInfo " + mni.toString());
    return mni;
  }

  handleLogRecord(LogRecord lr) {
    print("** logRecord " + lr.toString());
    return lr;
  }

  handleMeshPacket(MeshPacket mp) {
    print("** handleMeshPacket ");

    switch(mp.whichPayloadVariant()) {
      case MeshPacket_PayloadVariant.decoded:
        return handleDataPayload(mp.decoded);
        break;
      case MeshPacket_PayloadVariant.encrypted:
        return handleEncryptedPayload(mp.encrypted);
        break;
      default:
        print("-> unknown packet payload variant " + mp.whichPayloadVariant().toString());
        break;
    }
  }

  handleDataPayload(Data d) {
    switch(d.portnum) {
      case PortNum.TEXT_MESSAGE_APP:
        return handleTextMessagePortNum(d.payload);
        break;
      case PortNum.REMOTE_HARDWARE_APP:
        return false;
      case PortNum.POSITION_APP:
        return handlePositionPortNum(d.payload);
      case PortNum.NODEINFO_APP:
        return handleNodeInfoPortNum(d.payload);
      case PortNum.ROUTING_APP:
        return handleRoutingPortNum(d.payload);
      case PortNum.ADMIN_APP:
        return handleAdminPortNum(d.payload);
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

  handleEncryptedPayload(List<int> bytes) {
    print("*** handleEncryptedPayload - NOT HANDLED - FIXME");
    return false;
  }

  handleAdminPortNum(buf) {
    AdminMessage am = AdminMessage.fromBuffer(buf);
    print("*** handleAdminPortNum: " + am.toString());
    return am;
  }

  handlePositionPortNum(buf) {
    Position p = Position.fromBuffer(buf);
    print("*** handlePositionPortNum: " + p.toString());
    return p;
  }

  handleRoutingPortNum(buf) {
    Routing r = Routing.fromBuffer(buf);
    print("*** handleRoutingPortNum: " + r.toString());
    return r;
  }

  handleNodeInfoPortNum(buf) {
    User u = User.fromBuffer(buf);
    print("*** handleNodeInfoPortNum: " + u.toString());
    return u;
  }

  handleTextMessagePortNum(buf) {
    print("*** TEXT MESSAGE: " + buf.toString());
    return false;
  }
}