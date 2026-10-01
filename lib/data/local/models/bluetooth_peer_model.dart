class BluetoothPeerModel {
  final String id;
  final String deviceName;
  final String deviceAddress;
  final String lastSeen;
  final String syncStatus; // IDLE, CONNECTING, CONNECTED, SYNCING, FAILED

  const BluetoothPeerModel({
    required this.id,
    required this.deviceName,
    required this.deviceAddress,
    required this.lastSeen,
    this.syncStatus = 'IDLE',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_name': deviceName,
      'device_address': deviceAddress,
      'last_seen': lastSeen,
      'sync_status': syncStatus,
    };
  }

  factory BluetoothPeerModel.fromMap(Map<String, dynamic> map) {
    return BluetoothPeerModel(
      id: map['id'] as String,
      deviceName: map['device_name'] as String,
      deviceAddress: map['device_address'] as String,
      lastSeen: map['last_seen'] as String,
      syncStatus: (map['sync_status'] as String?) ?? 'IDLE',
    );
  }

  BluetoothPeerModel copyWith({
    String? id,
    String? deviceName,
    String? deviceAddress,
    String? lastSeen,
    String? syncStatus,
  }) {
    return BluetoothPeerModel(
      id: id ?? this.id,
      deviceName: deviceName ?? this.deviceName,
      deviceAddress: deviceAddress ?? this.deviceAddress,
      lastSeen: lastSeen ?? this.lastSeen,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
