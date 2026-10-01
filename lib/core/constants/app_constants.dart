class AppConstants {
  static const String appName = 'DisasterReady';
  static const String appVersion = '1.0.0';
  static const String dbName = 'disaster_ready.db';
  static const int dbVersion = 1;

  // Sync operations
  static const String syncOpCreate = 'CREATE';
  static const String syncOpUpdate = 'UPDATE';
  static const String syncOpDelete = 'DELETE';

  // Sync statuses
  static const String syncPending = 'PENDING';
  static const String syncInProgress = 'SYNCING';
  static const String syncCompleted = 'SYNCED';
  static const String syncFailed = 'FAILED';
  static const String syncConflict = 'CONFLICT';

  // Emergency request priorities
  static const String priorityLow = 'LOW';
  static const String priorityMedium = 'MEDIUM';
  static const String priorityHigh = 'HIGH';
  static const String priorityCritical = 'CRITICAL';

  // Emergency request statuses
  static const String statusRequested = 'Requested';
  static const String statusAccepted = 'Accepted';
  static const String statusTeamAssigned = 'Team Assigned';
  static const String statusInProgress = 'In Progress';
  static const String statusCompleted = 'Completed';
  static const String statusCancelled = 'Cancelled';
}
