class DatabaseException implements Exception {
  final String message;
  final dynamic originalError;

  const DatabaseException(this.message, [this.originalError]);

  @override
  String toString() => 'DatabaseException: $message ${originalError != null ? "($originalError)" : ""}';
}

class ValidationException implements Exception {
  final String message;

  const ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}

class SyncException implements Exception {
  final String message;
  final dynamic originalError;

  const SyncException(this.message, [this.originalError]);

  @override
  String toString() => 'SyncException: $message ${originalError != null ? "($originalError)" : ""}';
}
