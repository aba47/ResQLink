import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/models/emergency_service_model.dart';
import '../../data/repositories/facilities_repository.dart';
import '../../shared/widgets/status_badge.dart';

class EmergencyServicesScreen extends StatelessWidget {
  const EmergencyServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FacilitiesRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Services & Helplines'),
      ),
      body: FutureBuilder<List<EmergencyServiceModel>>(
        future: repo.getEmergencyServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final services = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return _buildServiceCard(context, service);
            },
          );
        },
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, EmergencyServiceModel service) {
    IconData icon;
    Color color;

    switch (service.serviceType.toLowerCase()) {
      case 'police':
        icon = Icons.local_police;
        color = Colors.indigo;
        break;
      case 'fire':
        icon = Icons.local_fire_department;
        color = Colors.deepOrange;
        break;
      case 'ambulance':
        icon = Icons.airport_shuttle;
        color = Colors.red;
        break;
      case 'disaster_management':
        icon = Icons.shield;
        color = Colors.teal;
        break;
      default:
        icon = Icons.phone_forwarded;
        color = Colors.blue;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Coverage: ${service.coverageArea ?? "All Locations"}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Direct Helpline: ${service.phone}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green[700]),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                StatusBadge(label: service.status),
                const SizedBox(height: 8),
                IconButton.filled(
                  icon: const Icon(Icons.call, size: 20),
                  style: IconButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling ${service.name} at ${service.phone}...')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
