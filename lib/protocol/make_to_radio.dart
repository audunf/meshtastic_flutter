import 'dart:convert' show utf8;
import 'package:meshtastic_flutter/proto-autogen/admin.pb.dart';
import 'package:meshtastic_flutter/proto-autogen/mesh.pb.dart';
import 'package:meshtastic_flutter/proto-autogen/portnums.pb.dart';
import 'package:meshtastic_flutter/proto-autogen/radioconfig.pb.dart';

class MakeToRadio {
  static int currentPacketId = 0;

  // Ask node for initial configuration
  static ToRadio wantConfig(int id) {
    ToRadio tr = new ToRadio();
    tr.wantConfigId = id;
    return tr;
  }

  static ToRadio textMessageApp(int fromNodeId, String text) {
    Data d = new Data(portnum: PortNum.TEXT_MESSAGE_APP, payload: utf8.encode(text), wantResponse: false);
    MeshPacket mp = new MeshPacket(from: fromNodeId, id: ++currentPacketId, hopLimit: 3, wantAck: true, priority: MeshPacket_Priority.DEFAULT, decoded: d);
    ToRadio tr = new ToRadio(packet: mp);
    return tr;
  }

  // Make the node send RadioConfig in response
  static ToRadio radioConfigRequest() {
    AdminMessage a = AdminMessage.create();
    a.getRadioRequest = true;
    return wrapAdminMessage(a);
  }

  static ToRadio radioConfigConfirmSetChannel() {
    AdminMessage a = AdminMessage.create();
    a.confirmSetChannel = true;
    return wrapAdminMessage(a);
  }

  static ToRadio radioConfigConfirmSetRadio() {
    AdminMessage a = AdminMessage.create();
    a.confirmSetRadio = true;
    return wrapAdminMessage(a);
  }

  static ToRadio setOwnerAdminMessage(longName, shortName) {
    User u = new User();
    // u.id = what?! The MAC?
    u.longName = longName;
    u.shortName = shortName;
    u.isLicensed = false;
    AdminMessage a = new AdminMessage();
    a.setOwner = u;
    return wrapAdminMessage(a);
  }

  // lots of possibilities - not sure changing them is required
  static ToRadio setRadioConfigUserPreferences() {
    AdminMessage a = AdminMessage.create();
    RadioConfig r = RadioConfig.create();
    a.setRadio = r;
    //r.preferences.positionBroadcastSecs
    //r.preferences.send_owner_interval
    // many, many more..
    return wrapAdminMessage(a);
  }

  static ToRadio peerInfo(int appVer) {
    ToRadio tr = new ToRadio();
    tr.peerInfo = new ToRadio_PeerInfo(appVersion: appVer, mqttGateway: false);
    return tr;
  }

  static ToRadio baseMeshPacket(int fromNodeId, int toNodeId, int channel) {
    MeshPacket mp = new MeshPacket();
    mp.from = fromNodeId; //The sending node number
    mp.to = toNodeId;
    mp.channel = channel;
    mp.id = ++currentPacketId;
    mp.hopLimit = 3;
    mp.wantAck = true;
    mp.priority = MeshPacket_Priority.DEFAULT;
    ToRadio tr = new ToRadio();
    tr.packet = mp;
    return tr;
  }

  static ToRadio encryptedMeshPacket(fromNodeId, toNodeId, channel, List<int> encryptedData) {
    ToRadio tr = baseMeshPacket(fromNodeId, toNodeId, channel);
    tr.packet.encrypted = encryptedData;
    return tr;
  }

  static ToRadio decodedMeshPacket(PortNum portNum, int fromNodeId, int toNodeId, int channel, List<int> payload) {
    Data d = new Data();
    d.portnum = portNum;
    d.payload = payload;
    d.wantResponse = false;

    ToRadio tr = baseMeshPacket(fromNodeId, toNodeId, channel);
    tr.packet.decoded = d;
    return tr;
  }

  static ToRadio wrapAdminMessage(AdminMessage a) {
    Data d = new Data();
    d.portnum = PortNum.ADMIN_APP;
    d.payload = a.writeToBuffer();

    MeshPacket mp = new MeshPacket();
    mp.id = ++currentPacketId;

    ToRadio tr = new ToRadio();
    tr.packet = mp;
    tr.packet.decoded = d;
    return tr;
  }
}
