import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../data/local/dao/user_dao.dart';
import '../../../data/local/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../offline_mode/widgets/offline_banner.dart';
import '../../../shared/widgets/emergency_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../app/routes.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final authRepo = context.read<AuthRepository>();
      final user = authRepo.currentUser ?? await UserDao().getActiveUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out? Your queued emergency requests will remain safely stored locally.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authRepo = context.read<AuthRepository>();
      await authRepo.logout();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connectivity = context.watch<ConnectivityService>();
    final authRepo = context.watch<AuthRepository>();
    if (authRepo.currentUser != null && _currentUser?.id != authRepo.currentUser?.id) {
      _currentUser = authRepo.currentUser;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('DisasterReady'),
        actions: [
          IconButton(
            tooltip: 'Offline & Sync Center',
            icon: const Icon(Icons.sync),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.syncCenter),
          ),
          IconButton(
            tooltip: connectivity.isManualOfflineMode ? 'Disable Offline Simulation' : 'Simulate Offline Mode',
            icon: Icon(
              connectivity.isManualOfflineMode ? Icons.wifi_off : Icons.wifi,
              color: connectivity.isManualOfflineMode ? Colors.amberAccent : Colors.white,
            ),
            onPressed: () {
              connectivity.setManualOfflineMode(!connectivity.isManualOfflineMode);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 2),
                  content: Text(connectivity.isManualOfflineMode
                      ? 'Offline Simulation Mode ACTIVE'
                      : 'Offline Simulation Mode DISABLED'),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Sign Out / Switch Account',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            InkWell(
              onTap: () => Navigator.pushNamed(context, AppRoutes.syncCenter),
              child: const OfflineBanner(),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadUser,
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          // User profile card
                          _buildProfileCard(theme),
                          const SizedBox(height: 16),

                          // Quick Action: SOS / Emergency Request
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withAlpha(75),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.pushNamed(context, AppRoutes.emergencyRequests),
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(50),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.sos,
                                          size: 36,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'EMERGENCY REQUESTS',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Create assistance requests & responder tracking.',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            'Emergency Management Modules',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),

                          // Full Feature Cards connecting to all 12 modules
                          EmergencyCard(
                            title: 'Active Disasters & Alerts',
                            subtitle: 'View active flood, cyclone, earthquake events & details',
                            icon: Icons.warning_amber_rounded,
                            iconColor: Colors.deepOrange,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.disasters),
                          ),
                          EmergencyCard(
                            title: 'Incident Field Reports',
                            subtitle: 'Report local damage, bridge collapse, or flood levels',
                            icon: Icons.report_problem_outlined,
                            iconColor: Colors.amber[800],
                            onTap: () => Navigator.pushNamed(context, AppRoutes.disasterReports),
                          ),
                          EmergencyCard(
                            title: 'Relief Shelters',
                            subtitle: 'Capacity, open status, supplies, and contact desks',
                            icon: Icons.night_shelter_outlined,
                            iconColor: Colors.indigo,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.shelters),
                          ),
                          EmergencyCard(
                            title: 'Hospitals & Medical Desks',
                            subtitle: 'Emergency contacts, beds, ICU, blood availability',
                            icon: Icons.local_hospital_outlined,
                            iconColor: Colors.teal,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.hospitals),
                          ),
                          EmergencyCard(
                            title: 'National Helplines & Services',
                            subtitle: 'NDRF (1078), Police (100), Ambulance (102), Fire (101)',
                            icon: Icons.phone_in_talk_outlined,
                            iconColor: Colors.green,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.emergencyServices),
                          ),
                          EmergencyCard(
                            title: 'Personal Emergency Contacts',
                            subtitle: 'Family members, doctors, and primary emergency contact',
                            icon: Icons.contact_phone_outlined,
                            iconColor: Colors.green[800],
                            onTap: () => Navigator.pushNamed(context, AppRoutes.emergencyContacts),
                          ),
                          EmergencyCard(
                            title: 'Designated Safe Zones',
                            subtitle: 'Pre-mapped high ground safe areas & guidelines',
                            icon: Icons.security_outlined,
                            iconColor: Colors.blue,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.safeZones),
                          ),
                          EmergencyCard(
                            title: 'Relief Supplies & Resources',
                            subtitle: 'Track food kits, drinking water, medicine inventories',
                            icon: Icons.inventory_2_outlined,
                            iconColor: Colors.brown,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.resources),
                          ),
                          EmergencyCard(
                            title: 'Offline & Sync Center',
                            subtitle: 'Inspect pending SQLite write queue & sync metrics',
                            icon: Icons.sync,
                            iconColor: Colors.purple,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.syncCenter),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withAlpha(30),
              child: Icon(Icons.person, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUser?.name ?? 'Emergency User',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Phone: ${_currentUser?.phone ?? "Not provided"}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            StatusBadge(label: _currentUser?.role ?? 'citizen'),
          ],
        ),
      ),
    );
  }
}
