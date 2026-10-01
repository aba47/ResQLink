import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../core/connectivity/connectivity_service.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/local/models/sync_queue_model.dart';
import '../../data/repositories/sync_repository.dart';
import '../../shared/widgets/status_badge.dart';

class SyncCenterScreen extends StatefulWidget {
  const SyncCenterScreen({super.key});

  @override
  State<SyncCenterScreen> createState() => _SyncCenterScreenState();
}

class _SyncCenterScreenState extends State<SyncCenterScreen> {
  bool _isSyncing = false;

  void _showConfigureUrlModal(BuildContext context) {
    final syncRepo = context.read<SyncRepository>();
    final controller = TextEditingController(text: syncRepo.apiClient.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configure Backend API URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select or enter backend host address:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'http://10.0.2.2:8000',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Emulator (10.0.2.2)'),
                  onPressed: () => controller.text = 'http://10.0.2.2:8000',
                ),
                ActionChip(
                  label: const Text('Localhost (8000)'),
                  onPressed: () => controller.text = 'http://127.0.0.1:8000',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              Navigator.pop(ctx);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              await syncRepo.updateBaseUrl(newUrl);
              controller.dispose();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Updated backend API URL to: $newUrl')),
                );
                setState(() {});
              }
            },
            child: const Text('Save & Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerManualSync() async {
    final connectivity = context.read<ConnectivityService>();
    final syncRepo = context.read<SyncRepository>();
    final messenger = ScaffoldMessenger.of(context);

    if (connectivity.isOffline) {
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text('Cannot sync: Device is currently in Offline Mode. Actions remain safely queued in SQLite.'),
        ),
      );
      return;
    }

    setState(() => _isSyncing = true);

    try {
      final result = await syncRepo.performSync();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: result.success ? Colors.green : Colors.red,
          content: Text(result.message),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text('Sync failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityService>();
    final syncRepo = context.watch<SyncRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline & Sync Center'),
        actions: [
          IconButton(
            tooltip: 'Bluetooth P2P Offline Sync',
            icon: const Icon(Icons.bluetooth_connected),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.bluetoothSync);
            },
          ),
          IconButton(
            tooltip: 'Configure Backend URL',
            icon: const Icon(Icons.settings_ethernet),
            onPressed: () => _showConfigureUrlModal(context),
          ),
          IconButton(
            tooltip: 'Clear completed sync logs',
            icon: const Icon(Icons.cleaning_services),
            onPressed: () async {
              await syncRepo.clearSynced();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cleaned completed sync records.')),
                );
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: connectivity.isOffline ? Colors.red[900] : Colors.green[800],
            child: Column(
              children: [
                Icon(
                  connectivity.isOffline ? Icons.cloud_off : Icons.cloud_done,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 10),
                Text(
                  connectivity.isOffline ? 'OFFLINE OPERATION MODE' : 'ONLINE MODE CONNECTED',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  connectivity.isOffline
                      ? 'All writes are persisted locally in SQLite and queued.'
                      : 'Connected to ${syncRepo.apiClient.baseUrl}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (syncRepo.lastSyncTimestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last Sync: ${DateUtilsHelper.formatDisplay(syncRepo.lastSyncTimestamp)}',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    connectivity.setManualOfflineMode(!connectivity.isManualOfflineMode);
                  },
                  icon: Icon(connectivity.isManualOfflineMode ? Icons.wifi : Icons.wifi_off),
                  label: Text(connectivity.isManualOfflineMode
                      ? 'Disable Simulated Offline Mode'
                      : 'Simulate Offline Mode (Field Test)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Action Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSyncing ? null : _triggerManualSync,
                    icon: _isSyncing
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.sync),
                    label: Text(_isSyncing ? 'Synchronizing with Backend...' : '2-Way Sync (Push & Pull)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending & Recent Sync Queue Records',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: FutureBuilder<List<SyncQueueModel>>(
              future: syncRepo.getPendingItems(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final queueItems = snapshot.data ?? [];

                if (queueItems.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.done_all, size: 60, color: Colors.green[400]),
                          const SizedBox(height: 12),
                          const Text(
                            'Queue is Empty',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'No pending records waiting to be synchronized.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: queueItems.length,
                  itemBuilder: (context, index) {
                    final item = queueItems[index];
                    return _buildQueueCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueCard(SyncQueueModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(label: item.operation),
                StatusBadge(label: item.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Entity: ${item.entityType.toUpperCase()} (#${item.entityId.substring(0, 8)})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Payload: ${item.payload.length > 70 ? "${item.payload.substring(0, 70)}..." : item.payload}',
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.blueGrey),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created: ${DateUtilsHelper.formatDisplay(item.createdAt)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  'Retries: ${item.retryCount}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            if (item.lastError != null) ...[
              const SizedBox(height: 6),
              Text(
                'Error: ${item.lastError}',
                style: const TextStyle(fontSize: 11, color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
