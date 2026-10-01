import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../data/repositories/sync_repository.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, child) {
        return FutureBuilder<int>(
          future: context.read<SyncRepository>().getPendingCount(),
          builder: (context, snapshot) {
            final pendingCount = snapshot.data ?? 0;
            final isOffline = connectivity.isOffline;

            if (!isOffline && pendingCount == 0) {
              return const SizedBox.shrink();
            }

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isOffline ? const Color(0xFFC62828) : const Color(0xFFEF6C00),
              child: Row(
                children: [
                  Icon(
                    isOffline ? Icons.cloud_off : Icons.sync,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isOffline
                          ? (pendingCount > 0
                              ? 'Offline Mode — $pendingCount action(s) stored locally'
                              : 'Offline Mode — Working with local database')
                          : 'Online — $pendingCount action(s) waiting to sync',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (connectivity.isManualOfflineMode)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'SIMULATED',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
