import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/connectivity/connectivity_service.dart';
import '../core/network/api_client.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/emergency_repository.dart';
import '../data/repositories/disaster_repository.dart';
import '../data/repositories/facilities_repository.dart';
import '../data/repositories/sync_repository.dart';
import 'routes.dart';
import 'theme.dart';

class DisasterReadyApp extends StatefulWidget {
  const DisasterReadyApp({super.key});

  @override
  State<DisasterReadyApp> createState() => _DisasterReadyAppState();
}

class _DisasterReadyAppState extends State<DisasterReadyApp> {
  late final ApiClient _apiClient;
  late final AuthRepository _authRepo;
  late final SyncRepository _syncRepo;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _authRepo = AuthRepository(apiClient: _apiClient);
    _syncRepo = SyncRepository(apiClient: _apiClient);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider.value(value: _authRepo),
        ChangeNotifierProvider.value(value: _syncRepo),
        Provider(create: (_) => EmergencyRepository()),
        Provider(create: (_) => DisasterRepository()),
        Provider(create: (_) => FacilitiesRepository()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
      ),
    );
  }
}
