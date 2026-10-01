import 'package:flutter/material.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/local/models/disaster_model.dart';
import '../../shared/widgets/status_badge.dart';

class DisasterDetailScreen extends StatelessWidget {
  final DisasterModel disaster;

  const DisasterDetailScreen({super.key, required this.disaster});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(disaster.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusBadge(label: disaster.type.toUpperCase()),
                        StatusBadge(label: disaster.severity.toUpperCase()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      disaster.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_pin, color: Colors.red, size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            disaster.location,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Metrics Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Status',
                    value: disaster.status.toUpperCase(),
                    icon: Icons.info_outline,
                    color: disaster.status.toLowerCase() == 'active' ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Radius',
                    value: disaster.radiusKm > 0 ? '${disaster.radiusKm} km' : 'N/A',
                    icon: Icons.radar,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Affected Pop.',
                    value: disaster.affectedPopulation > 0 ? '${disaster.affectedPopulation}' : 'Unknown',
                    icon: Icons.people_outline,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Description
            const Text(
              'Incident Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  disaster.description ?? 'No specific incident narrative provided. Follow local emergency guidelines and monitor shelter status.',
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Metadata Card
            Card(
              color: theme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetaRow('Reported Time', DateUtilsHelper.formatDisplay(disaster.reportedAt)),
                    const Divider(height: 16),
                    _buildMetaRow('Last Updated', DateUtilsHelper.formatDisplay(disaster.updatedAt)),
                    const Divider(height: 16),
                    _buildMetaRow('Data Source', disaster.source.toUpperCase()),
                    if (disaster.latitude != null && disaster.longitude != null) ...[
                      const Divider(height: 16),
                      _buildMetaRow('GPS Coordinates', '${disaster.latitude!.toStringAsFixed(4)}, ${disaster.longitude!.toStringAsFixed(4)}'),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
