import 'bluetooth_envelope.dart';

class ValidationResult {
  final bool isValid;
  final String? error;
  final Map<String, dynamic>? sanitizedPayload;

  const ValidationResult.valid(this.sanitizedPayload)
      : isValid = true,
        error = null;

  const ValidationResult.invalid(this.error)
      : isValid = false,
        sanitizedPayload = null;
}

class BluetoothValidator {
  static const Set<String> allowedEntityTypes = {
    'emergency_request',
    'disaster_report',
    'shelter',
    'hospital',
    'emergency_contact',
    'safe_zone',
    'resource',
  };

  static const Set<String> allowedPriorities = {
    'LOW',
    'MEDIUM',
    'HIGH',
    'CRITICAL',
  };

  static const Set<String> allowedOperations = {
    'INSERT',
    'UPDATE',
  };

  /// Validate protocol envelope and sanitize untrusted incoming data.
  static ValidationResult validateEnvelope(BluetoothEnvelope envelope) {
    // 1. Protocol Version Check
    if (envelope.protocolVersion != BluetoothEnvelope.currentProtocolVersion) {
      return ValidationResult.invalid(
        'Unsupported protocol version "${envelope.protocolVersion}". Expected "${BluetoothEnvelope.currentProtocolVersion}".',
      );
    }

    // 2. Envelope Integrity Checks
    if (envelope.messageId.trim().isEmpty) {
      return const ValidationResult.invalid('Missing or empty messageId.');
    }
    if (envelope.deviceId.trim().isEmpty) {
      return const ValidationResult.invalid('Missing or empty deviceId.');
    }
    if (envelope.timestamp.trim().isEmpty) {
      return const ValidationResult.invalid('Missing or empty timestamp.');
    }
    if (!allowedEntityTypes.contains(envelope.entityType)) {
      return ValidationResult.invalid('Unsupported entity type "${envelope.entityType}".');
    }
    if (!allowedOperations.contains(envelope.operation.toUpperCase())) {
      return ValidationResult.invalid('Invalid operation "${envelope.operation}". Must be INSERT or UPDATE.');
    }
    if (envelope.payload.isEmpty) {
      return const ValidationResult.invalid('Payload cannot be empty.');
    }

    // 3. Security Sanitize Payload (Never Trust Rules)
    final sanitized = Map<String, dynamic>.from(envelope.payload);

    // Rule: Strip remote admin / role escalation claims
    sanitized.remove('is_admin');
    if (sanitized.containsKey('role')) {
      sanitized['role'] = 'CITIZEN'; // Force untrusted peer role to citizen
    }

    // Rule: Validate and sanitize priority claim
    if (sanitized.containsKey('priority')) {
      final prio = (sanitized['priority'] as String?)?.toUpperCase();
      if (prio == null || !allowedPriorities.contains(prio)) {
        sanitized['priority'] = 'MEDIUM'; // Clamp to safe default
      } else {
        sanitized['priority'] = prio;
      }
    }

    // Rule: Untrusted peers cannot unilaterally set status to Completed or Team Assigned
    if (envelope.entityType == 'emergency_request' && sanitized.containsKey('status')) {
      final status = sanitized['status'] as String?;
      if (status == 'Completed' || status == 'Team Assigned' || status == 'In Progress') {
        // Untrusted peer cannot mark requests finished or assign teams remotely
        sanitized['status'] = 'Requested';
      }
    }

    // Rule: Validate resource quantity bounds
    if (envelope.entityType == 'resource' && sanitized.containsKey('quantity')) {
      final qty = sanitized['quantity'];
      if (qty is! int || qty < 0 || qty > 100000) {
        return const ValidationResult.invalid('Invalid resource quantity claim: out of bounds.');
      }
    }

    // Entity-specific required field validations
    if (envelope.entityType == 'emergency_request') {
      if ((sanitized['id'] as String?)?.trim().isEmpty ?? true) {
        return const ValidationResult.invalid('Emergency request must have a non-empty id.');
      }
      if ((sanitized['user_name'] as String?)?.trim().isEmpty ?? true) {
        return const ValidationResult.invalid('Emergency request must have a non-empty user_name.');
      }
      if ((sanitized['phone'] as String?)?.trim().isEmpty ?? true) {
        return const ValidationResult.invalid('Emergency request must have a non-empty phone.');
      }
    } else if (envelope.entityType == 'disaster_report') {
      if ((sanitized['id'] as String?)?.trim().isEmpty ?? true) {
        return const ValidationResult.invalid('Disaster report must have a non-empty id.');
      }
      if ((sanitized['title'] as String?)?.trim().isEmpty ?? true) {
        return const ValidationResult.invalid('Disaster report must have a non-empty title.');
      }
    }

    return ValidationResult.valid(sanitized);
  }
}
