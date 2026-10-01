import 'package:flutter/material.dart';
import '../../core/bluetooth/bluetooth_p2p_service.dart';
import '../../core/bluetooth/bluetooth_transport.dart';
import '../../core/database/database_helper.dart';
import '../../data/local/dao/bluetooth_peer_dao.dart';
import '../../data/local/dao/disaster_report_dao.dart';
import '../../data/local/dao/emergency_contact_dao.dart';
import '../../data/local/dao/emergency_request_dao.dart';
import '../../data/local/dao/hospital_dao.dart';
import '../../data/local/dao/resource_dao.dart';
import '../../data/local/dao/safe_zone_dao.dart';
import '../../data/local/dao/shelter_dao.dart';
import '../offline_mode/widgets/offline_banner.dart';

class BluetoothSyncScreen extends StatefulWidget {
  final BluetoothP2pService? p2pService;

  const BluetoothSyncScreen({super.key, this.p2pService});

  @override
  State<BluetoothSyncScreen> createState() => _BluetoothSyncScreenState();
}

class _BluetoothSyncScreenState extends State<BluetoothSyncScreen> {
  late BluetoothP2pService _service;
  bool _isSupported = true;
  bool _isEnabled = true;
  bool _isLoading = false;
  String _selectedEntityType = 'emergency_request';

  @override
  void initState() {
    super.initState();
    if (widget.p2pService != null) {
      _service = widget.p2pService!;
    } else {
      final dbHelper = DatabaseHelper.instance;
      _service = BluetoothP2pService(
        transport: NativeBluetoothTransport(),
        peerDao: BluetoothPeerDao(dbHelper: dbHelper),
        requestDao: EmergencyRequestDao(dbHelper: dbHelper),
        reportDao: DisasterReportDao(dbHelper: dbHelper),
        shelterDao: ShelterDao(dbHelper: dbHelper),
        hospitalDao: HospitalDao(dbHelper: dbHelper),
        contactDao: EmergencyContactDao(dbHelper: dbHelper),
        safeZoneDao: SafeZoneDao(dbHelper: dbHelper),
        resourceDao: ResourceDao(dbHelper: dbHelper),
      );
    }
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);
    final supported = await _service.checkCapability();
    final enabled = await _service.checkEnabled();
    if (mounted) {
      setState(() {
        _isSupported = supported;
        _isEnabled = enabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTestEntity() async {
    if (!_service.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect to a nearby peer first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    Map<String, dynamic> samplePayload;
    if (_selectedEntityType == 'emergency_request') {
      samplePayload = {
        'id': 'p2p-req-${DateTime.now().millisecondsSinceEpoch}',
        'user_name': 'P2P Citizen',
        'phone': '9110000000',
        'request_type': 'medical',
        'priority': 'HIGH',
        'status': 'Requested',
        'description': 'P2P transmitted emergency medical request',
        'location': 'Offline Zone Beta',
        'people_count': 2,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
    } else {
      samplePayload = {
        'id': 'p2p-rep-${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Bridge Blocked - P2P Alert',
        'hazard_type': 'flood',
        'severity': 'HIGH',
        'description': 'Reported via peer-to-peer Bluetooth connection',
        'location': 'Northern Crossing',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      };
    }

    final success = await _service.sendEntity(
      entityType: _selectedEntityType,
      operation: 'INSERT',
      version: 1,
      payload: samplePayload,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Transmitted envelope to peer!' : 'Transmission failed.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Bluetooth Offline Sync (P2P)'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Status',
                onPressed: _checkStatus,
              ),
            ],
          ),
          body: Column(
            children: [
              const OfflineBanner(),
              // Physical device notice card
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade900.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade400, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HARDWARE STATUS & VERIFICATION',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'PHYSICAL BLUETOOTH TEST: NOT TESTED / REQUIRES 2 PHYSICAL PHONES.\nProtocol, validation, deduplication, and staging queue are verified via unit & protocol suites.',
                            style: TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bluetooth Capability Card
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hardware: ${_isSupported ? "Supported" : "Not Detected"}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isSupported ? Colors.greenAccent : Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Adapter: ${_isEnabled ? "Enabled" : "Disabled / Permission Needed"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isEnabled ? Colors.greenAccent : Colors.orangeAccent,
                            ),
                          ),
                          if (_service.connectedPeer != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Connected: ${_service.connectedPeer!.deviceName}',
                              style: const TextStyle(fontSize: 12, color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                      ElevatedButton.icon(
                        icon: _service.isScanning
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.bluetooth_searching, size: 18),
                        label: Text(_service.isScanning ? 'Scanning...' : 'Scan Nearby'),
                        onPressed: _service.isScanning ? _service.stopDiscovery : _service.startDiscovery,
                      ),
                    ],
                  ),
                ),
              ),

              // Transmit Control Card
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Text('Share: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedEntityType,
                        items: const [
                          DropdownMenuItem(
                            value: 'emergency_request',
                            child: Text('Emergency Request'),
                          ),
                          DropdownMenuItem(
                            value: 'disaster_report',
                            child: Text('Disaster Report'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedEntityType = val);
                        },
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Transmit P2P'),
                        onPressed: _isLoading ? null : _sendTestEntity,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Peer Devices & Transfer Logs Tabs
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(icon: Icon(Icons.devices), text: 'Nearby Peers'),
                          Tab(icon: Icon(Icons.sync_alt), text: 'Transfer Logs'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // 1. Nearby Peers List
                            _service.discoveredPeers.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Text(
                                        _service.isScanning
                                            ? 'Scanning for nearby DisasterReady devices via Bluetooth...'
                                            : 'No nearby peers detected.\nTap "Scan Nearby" to discover devices.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white60),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _service.discoveredPeers.length,
                                    itemBuilder: (context, index) {
                                      final peer = _service.discoveredPeers[index];
                                      final isThisConnected = _service.connectedPeer?.deviceAddress == peer.deviceAddress;
                                      return ListTile(
                                        leading: const Icon(Icons.phone_android, color: Colors.blueAccent),
                                        title: Text(peer.deviceName),
                                        subtitle: Text('${peer.deviceAddress} • ${peer.syncStatus}'),
                                        trailing: isThisConnected
                                            ? OutlinedButton(
                                                onPressed: _service.disconnect,
                                                child: const Text('Disconnect'),
                                              )
                                            : ElevatedButton(
                                                onPressed: () => _service.connect(peer),
                                                child: const Text('Connect'),
                                              ),
                                      );
                                    },
                                  ),

                            // 2. Transfer Logs & Staging Queue
                            _service.transferLogs.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No P2P transfers yet.\nConnect to a peer and transmit data.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white60),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _service.transferLogs.length,
                                    itemBuilder: (context, index) {
                                      final log = _service.transferLogs[index];
                                      final isOut = log.direction == 'OUTBOUND';
                                      return ListTile(
                                        dense: true,
                                        leading: Icon(
                                          isOut ? Icons.arrow_upward : Icons.arrow_downward,
                                          color: isOut ? Colors.orangeAccent : Colors.greenAccent,
                                        ),
                                        title: Text(
                                          '${log.direction} • ${log.entityType} [${log.status}]',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        subtitle: Text(
                                          '${log.details}\n${log.timestamp}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
