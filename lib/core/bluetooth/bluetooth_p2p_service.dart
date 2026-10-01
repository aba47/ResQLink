import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/local/dao/bluetooth_peer_dao.dart';
import '../../data/local/dao/disaster_report_dao.dart';
import '../../data/local/dao/emergency_contact_dao.dart';
import '../../data/local/dao/emergency_request_dao.dart';
import '../../data/local/dao/hospital_dao.dart';
import '../../data/local/dao/resource_dao.dart';
import '../../data/local/dao/safe_zone_dao.dart';
import '../../data/local/dao/shelter_dao.dart';
import '../../data/local/models/bluetooth_peer_model.dart';
import '../../data/local/models/disaster_report_model.dart';
import '../../data/local/models/emergency_contact_model.dart';
import '../../data/local/models/emergency_request_model.dart';
import '../../data/local/models/hospital_model.dart';
import '../../data/local/models/resource_model.dart';
import '../../data/local/models/safe_zone_model.dart';
import '../../data/local/models/shelter_model.dart';
import 'bluetooth_envelope.dart';
import 'bluetooth_staging.dart';
import 'bluetooth_transport.dart';

class TransferLog {
  final String id;
  final String timestamp;
  final String direction; // INBOUND, OUTBOUND
  final String entityType;
  final String status; // STAGED, COMMITTED, REJECTED, ACK_RECEIVED
  final String details;

  TransferLog({
    required this.id,
    required this.timestamp,
    required this.direction,
    required this.entityType,
    required this.status,
    required this.details,
  });
}

class BluetoothP2pService extends ChangeNotifier {
  final BluetoothTransport transport;
  final BluetoothPeerDao peerDao;
  final EmergencyRequestDao requestDao;
  final DisasterReportDao reportDao;
  final ShelterDao shelterDao;
  final HospitalDao hospitalDao;
  final EmergencyContactDao contactDao;
  final SafeZoneDao safeZoneDao;
  final ResourceDao resourceDao;
  final String localDeviceId;

  final BluetoothStagingQueue stagingQueue = BluetoothStagingQueue();
  final List<TransferLog> _transferLogs = [];
  final List<BluetoothPeerModel> _discoveredPeers = [];
  StreamSubscription<String>? _incomingSub;

  bool _isScanning = false;
  BluetoothPeerModel? _connectedPeer;

  List<TransferLog> get transferLogs => List.unmodifiable(_transferLogs);
  List<BluetoothPeerModel> get discoveredPeers => List.unmodifiable(_discoveredPeers);
  bool get isScanning => _isScanning;
  bool get isConnected => transport.isConnected;
  BluetoothPeerModel? get connectedPeer => _connectedPeer;

  BluetoothP2pService({
    required this.transport,
    required this.peerDao,
    required this.requestDao,
    required this.reportDao,
    required this.shelterDao,
    required this.hospitalDao,
    required this.contactDao,
    required this.safeZoneDao,
    required this.resourceDao,
    String? localDeviceId,
  }) : localDeviceId = localDeviceId ?? const Uuid().v4() {
    _initIncomingListener();
  }

  void _initIncomingListener() {
    _incomingSub = transport.incomingDataStream.listen(_handleIncomingData);
  }

  @override
  void dispose() {
    _incomingSub?.cancel();
    super.dispose();
  }

  Future<bool> checkCapability() async {
    return await transport.isSupported();
  }

  Future<bool> checkEnabled() async {
    return await transport.isEnabled();
  }

  Future<bool> requestPermissions() async {
    return await transport.requestPermissions();
  }

  Future<void> startDiscovery() async {
    _isScanning = true;
    _discoveredPeers.clear();
    notifyListeners();

    try {
      await for (final peer in transport.discoverDevices()) {
        if (!_discoveredPeers.any((p) => p.deviceAddress == peer.deviceAddress)) {
          _discoveredPeers.add(peer);
          await peerDao.upsert(peer);
          notifyListeners();
        }
      }
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> stopDiscovery() async {
    await transport.stopDiscovery();
    _isScanning = false;
    notifyListeners();
  }

  Future<bool> connect(BluetoothPeerModel peer) async {
    final success = await transport.connect(peer.deviceAddress);
    if (success) {
      _connectedPeer = peer;
      await peerDao.updateSyncStatus(peer.id, 'CONNECTED');
      _addLog('OUTBOUND', 'HANDSHAKE', 'CONNECTED', 'Connected to peer ${peer.deviceName}');
      // Send Handshake
      final handshakeEnvelope = BluetoothEnvelope(
        messageId: const Uuid().v4(),
        deviceId: localDeviceId,
        timestamp: DateUtilsHelper.nowUtcIso(),
        entityType: 'safe_zone',
        operation: 'INSERT',
        version: 1,
        payload: {
          'handshake': true,
          'device_id': localDeviceId,
          'device_name': peer.deviceName,
        },
      );
      await transport.sendData(handshakeEnvelope.toJson());
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> disconnect() async {
    await transport.disconnect();
    if (_connectedPeer != null) {
      await peerDao.updateSyncStatus(_connectedPeer!.id, 'IDLE');
    }
    _connectedPeer = null;
    notifyListeners();
  }

  /// Handle incoming raw data stream from transport
  Future<void> _handleIncomingData(String rawJson) async {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) return;

      // Check if this is an ACK
      if (decoded.containsKey('ackFor')) {
        final ack = BluetoothAck.fromMap(decoded);
        _addLog('INBOUND', 'ACK', ack.status, 'ACK for msg: ${ack.ackFor} - ${ack.reason ?? ''}');
        notifyListeners();
        return;
      }

      // Parse envelope
      final envelope = BluetoothEnvelope.fromMap(decoded);

      // Check for handshake
      if (envelope.payload['handshake'] == true) {
        _addLog('INBOUND', 'HANDSHAKE', 'ACCEPTED', 'P2P Handshake verified with protocol v${envelope.protocolVersion}');
        notifyListeners();
        return;
      }

      // Check Duplicate
      if (stagingQueue.isDuplicate(envelope.messageId)) {
        _addLog('INBOUND', envelope.entityType, 'DUPLICATE', 'Duplicate message rejected: ${envelope.messageId}');
        await _sendAck(envelope.messageId, 'DUPLICATE', 'Message already processed');
        notifyListeners();
        return;
      }

      // Step 1: Stage Envelope
      final stagedItem = stagingQueue.stage(envelope);
      _addLog('INBOUND', envelope.entityType, 'STAGED', 'Staged message ${envelope.messageId}');

      // Step 2: Validate Envelope & Sanitize Payload
      final valResult = stagingQueue.validateItem(stagedItem);
      if (!valResult.isValid) {
        stagingQueue.markRejected(stagedItem, valResult.error ?? 'Validation failed');
        _addLog('INBOUND', envelope.entityType, 'REJECTED', 'Rejected: ${valResult.error}');
        await _sendAck(envelope.messageId, 'REJECTED', valResult.error);
        notifyListeners();
        return;
      }

      // Step 3: Commit to SQLite Primary Tables
      await _commitStagedItem(stagedItem);
      stagingQueue.markCommitted(stagedItem);
      _addLog('INBOUND', envelope.entityType, 'COMMITTED', 'Successfully committed ${envelope.entityType} to SQLite');

      // Step 4: Send ACK back to sender
      await _sendAck(envelope.messageId, 'ACCEPTED', 'Successfully committed');
      notifyListeners();
    } catch (e) {
      _addLog('INBOUND', 'UNKNOWN', 'ERROR', 'Error handling incoming data: $e');
      notifyListeners();
    }
  }

  Future<void> _commitStagedItem(BluetoothStagingItem item) async {
    final payload = item.validatedPayload!;
    final entityType = item.envelope.entityType;

    switch (entityType) {
      case 'emergency_request':
        final req = EmergencyRequestModel.fromMap(payload);
        await requestDao.insert(req);
        break;
      case 'disaster_report':
        final rep = DisasterReportModel.fromMap(payload);
        await reportDao.insert(rep);
        break;
      case 'shelter':
        final shelter = ShelterModel.fromMap(payload);
        await shelterDao.insert(shelter);
        break;
      case 'hospital':
        final hospital = HospitalModel.fromMap(payload);
        await hospitalDao.insert(hospital);
        break;
      case 'emergency_contact':
        final contact = EmergencyContactModel.fromMap(payload);
        await contactDao.insert(contact);
        break;
      case 'safe_zone':
        final zone = SafeZoneModel.fromMap(payload);
        await safeZoneDao.insert(zone);
        break;
      case 'resource':
        final res = ResourceModel.fromMap(payload);
        await resourceDao.insert(res);
        break;
    }
  }

  Future<void> _sendAck(String incomingMessageId, String status, String? reason) async {
    final ack = BluetoothAck(
      messageId: const Uuid().v4(),
      ackFor: incomingMessageId,
      status: status,
      reason: reason,
    );
    await transport.sendData(ack.toJson());
  }

  /// Send local entity to connected peer
  Future<bool> sendEntity({
    required String entityType,
    required String operation,
    required int version,
    required Map<String, dynamic> payload,
  }) async {
    if (!transport.isConnected) {
      _addLog('OUTBOUND', entityType, 'FAILED', 'Cannot send: Not connected to any peer');
      notifyListeners();
      return false;
    }

    final messageId = const Uuid().v4();
    final envelope = BluetoothEnvelope(
      messageId: messageId,
      deviceId: localDeviceId,
      timestamp: DateUtilsHelper.nowUtcIso(),
      entityType: entityType,
      operation: operation,
      version: version,
      payload: payload,
    );

    _addLog('OUTBOUND', entityType, 'SENDING', 'Transferring message $messageId');
    try {
      await transport.sendData(envelope.toJson());
      _addLog('OUTBOUND', entityType, 'SENT', 'Sent $entityType to peer');
      notifyListeners();
      return true;
    } catch (e) {
      _addLog('OUTBOUND', entityType, 'ERROR', 'Transfer failed: $e');
      notifyListeners();
      return false;
    }
  }

  void _addLog(String direction, String entityType, String status, String details) {
    _transferLogs.insert(
      0,
      TransferLog(
        id: const Uuid().v4(),
        timestamp: DateUtilsHelper.nowUtcIso(),
        direction: direction,
        entityType: entityType,
        status: status,
        details: details,
      ),
    );
    if (_transferLogs.length > 100) {
      _transferLogs.removeLast();
    }
  }
}
