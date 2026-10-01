import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/connectivity/connectivity_service.dart';
import '../data/repositories/emergency_repository.dart';
import '../data/repositories/disaster_repository.dart';
import '../data/repositories/facilities_repository.dart';
import '../data/repositories/sync_repository.dart';
import 'routes.dart';
import 'theme.dart';

class DisasterReadyApp extends StatelessWidget {
  const DisasterReadyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        Provider(create: (_) => EmergencyRepository()),
        Provider(create: (_) => DisasterRepository()),
        Provider(create: (_) => FacilitiesRepository()),
        Provider(create: (_) => SyncRepository()),
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
