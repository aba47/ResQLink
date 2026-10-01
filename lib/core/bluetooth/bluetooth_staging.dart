import 'bluetooth_envelope.dart';
import 'bluetooth_validator.dart';

enum StagingStatus {
  staged,
  validated,
  committed,
  rejected,
}

class BluetoothStagingItem {
  final String id;
  final BluetoothEnvelope envelope;
  final DateTime receivedAt;
  StagingStatus status;
  Map<String, dynamic>? validatedPayload;
  String? error;

  BluetoothStagingItem({
    required this.id,
    required this.envelope,
    required this.receivedAt,
    this.status = StagingStatus.staged,
    this.validatedPayload,
    this.error,
  });

  bool get isCommitted => status == StagingStatus.committed;
  bool get isRejected => status == StagingStatus.rejected;
}

class BluetoothStagingQueue {
  final List<BluetoothStagingItem> _items = [];
  final Set<String> _processedMessageIds = {};

  List<BluetoothStagingItem> get items => List.unmodifiable(_items);
  List<BluetoothStagingItem> get stagedItems =>
      _items.where((i) => i.status == StagingStatus.staged).toList();
  List<BluetoothStagingItem> get committedItems =>
      _items.where((i) => i.status == StagingStatus.committed).toList();

  /// Check for duplicate messageId
  bool isDuplicate(String messageId) {
    return _processedMessageIds.contains(messageId);
  }

  /// Stage an incoming envelope before validation
  BluetoothStagingItem stage(BluetoothEnvelope envelope) {
    if (isDuplicate(envelope.messageId)) {
      final existing = _items.firstWhere((i) => i.envelope.messageId == envelope.messageId);
      return existing;
    }

    final item = BluetoothStagingItem(
      id: envelope.messageId,
      envelope: envelope,
      receivedAt: DateTime.now(),
      status: StagingStatus.staged,
    );
    _items.add(item);
    return item;
  }

  /// Validate staged item
  ValidationResult validateItem(BluetoothStagingItem item) {
    final result = BluetoothValidator.validateEnvelope(item.envelope);
    if (result.isValid) {
      item.status = StagingStatus.validated;
      item.validatedPayload = result.sanitizedPayload;
    } else {
      item.status = StagingStatus.rejected;
      item.error = result.error;
    }
    return result;
  }

  /// Mark item as committed to SQLite
  void markCommitted(BluetoothStagingItem item) {
    item.status = StagingStatus.committed;
    _processedMessageIds.add(item.envelope.messageId);
  }

  /// Mark item as rejected
  void markRejected(BluetoothStagingItem item, String reason) {
    item.status = StagingStatus.rejected;
    item.error = reason;
    _processedMessageIds.add(item.envelope.messageId);
  }

  void clear() {
    _items.clear();
    _processedMessageIds.clear();
  }
}
