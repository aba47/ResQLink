import 'package:flutter/material.dart';
import '../features/auth/login_screen.dart';
import '../features/bluetooth_sync/bluetooth_sync_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/disasters/disasters_screen.dart';
import '../features/emergency_requests/emergency_requests_screen.dart';
import '../features/facilities/emergency_contacts_screen.dart';
import '../features/facilities/emergency_services_screen.dart';
import '../features/facilities/hospitals_screen.dart';
import '../features/facilities/resources_screen.dart';
import '../features/facilities/safe_zones_screen.dart';
import '../features/facilities/shelters_screen.dart';
import '../features/offline_mode/sync_center_screen.dart';
import '../features/reports/disaster_reports_screen.dart';
import '../features/splash/splash_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String disasters = '/disasters';
  static const String emergencyRequests = '/emergency_requests';
  static const String disasterReports = '/disaster_reports';
  static const String shelters = '/shelters';
  static const String hospitals = '/hospitals';
  static const String emergencyServices = '/emergency_services';
  static const String emergencyContacts = '/emergency_contacts';
  static const String safeZones = '/safe_zones';
  static const String resources = '/resources';
  static const String syncCenter = '/sync_center';
  static const String bluetoothSync = '/bluetooth_sync';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginScreen(),
      dashboard: (context) => const DashboardScreen(),
      disasters: (context) => const DisastersScreen(),
      emergencyRequests: (context) => const EmergencyRequestsScreen(),
      disasterReports: (context) => const DisasterReportsScreen(),
      shelters: (context) => const SheltersScreen(),
      hospitals: (context) => const HospitalsScreen(),
      emergencyServices: (context) => const EmergencyServicesScreen(),
      emergencyContacts: (context) => const EmergencyContactsScreen(),
      safeZones: (context) => const SafeZonesScreen(),
      resources: (context) => const ResourcesScreen(),
      syncCenter: (context) => const SyncCenterScreen(),
      bluetoothSync: (context) => const BluetoothSyncScreen(),
    };
  }
}
