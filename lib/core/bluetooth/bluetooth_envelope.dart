import 'dart:convert';

class BluetoothEnvelope {
  static const String currentProtocolVersion = '1.0';

  final String protocolVersion;
  final String messageId;
  final String deviceId;
  final String timestamp;
  final String entityType; // emergency_request, disaster_report, shelter, hospital, emergency_contact, safe_zone, resource
  final String operation; // INSERT, UPDATE
  final int version;
  final Map<String, dynamic> payload;

  const BluetoothEnvelope({
    this.protocolVersion = currentProtocolVersion,
    required this.messageId,
    required this.deviceId,
    required this.timestamp,
    required this.entityType,
    required this.operation,
    required this.version,
    required this.payload,
  });

  Map<String, dynamic> toMap() {
    return {
      'protocolVersion': protocolVersion,
      'messageId': messageId,
      'deviceId': deviceId,
      'timestamp': timestamp,
      'entityType': entityType,
      'operation': operation,
      'version': version,
      'payload': payload,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory BluetoothEnvelope.fromMap(Map<String, dynamic> map) {
    return BluetoothEnvelope(
      protocolVersion: (map['protocolVersion'] as String?) ?? '',
      messageId: (map['messageId'] as String?) ?? '',
      deviceId: (map['deviceId'] as String?) ?? '',
      timestamp: (map['timestamp'] as String?) ?? '',
      entityType: (map['entityType'] as String?) ?? '',
      operation: (map['operation'] as String?) ?? 'INSERT',
      version: (map['version'] as int?) ?? 1,
      payload: (map['payload'] as Map<String, dynamic>?) ?? {},
    );
  }

  factory BluetoothEnvelope.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected JSON object for BluetoothEnvelope');
    }
    return BluetoothEnvelope.fromMap(decoded);
  }
}

class BluetoothAck {
  final String protocolVersion;
  final String messageId;
  final String ackFor;
  final String status; // ACCEPTED, DUPLICATE, REJECTED
  final String? reason;

  const BluetoothAck({
    this.protocolVersion = BluetoothEnvelope.currentProtocolVersion,
    required this.messageId,
    required this.ackFor,
    required this.status,
    this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'protocolVersion': protocolVersion,
      'messageId': messageId,
      'ackFor': ackFor,
      'status': status,
      if (reason != null) 'reason': reason,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory BluetoothAck.fromMap(Map<String, dynamic> map) {
    return BluetoothAck(
      protocolVersion: (map['protocolVersion'] as String?) ?? BluetoothEnvelope.currentProtocolVersion,
      messageId: (map['messageId'] as String?) ?? '',
      ackFor: (map['ackFor'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'REJECTED',
      reason: map['reason'] as String?,
    );
  }
}
