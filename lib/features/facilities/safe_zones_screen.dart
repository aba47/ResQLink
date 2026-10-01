import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/local/models/safe_zone_model.dart';
import '../../data/repositories/facilities_repository.dart';
import '../../shared/widgets/status_badge.dart';

class SafeZonesScreen extends StatefulWidget {
  const SafeZonesScreen({super.key});

  @override
  State<SafeZonesScreen> createState() => _SafeZonesScreenState();
}

class _SafeZonesScreenState extends State<SafeZonesScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FacilitiesRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Designated Safe Zones'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSafeZoneModal(context),
        icon: const Icon(Icons.add_location),
        label: const Text('Designate Zone'),
        backgroundColor: Colors.blue[700],
      ),
      body: FutureBuilder<List<SafeZoneModel>>(
        future: repo.getSafeZones(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final zones = snapshot.data ?? [];

          if (zones.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.security_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'No Safe Zones Recorded',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Designate high-ground parks, stadium grounds, or elevated concrete buildings as safe zones.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: zones.length,
            itemBuilder: (context, index) {
              final zone = zones[index];
              return _buildZoneCard(context, zone);
            },
          );
        },
      ),
    );
  }

  Widget _buildZoneCard(BuildContext context, SafeZoneModel zone) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    zone.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                StatusBadge(label: zone.safetyLevel),
              ],
            ),
            if (zone.description != null && zone.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                zone.description!,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.radar, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  'Radius: ${zone.radiusMeters.toInt()}m',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.pin_drop, size: 16, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  '${zone.latitude.toStringAsFixed(4)}, ${zone.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            if (zone.guidelines != null && zone.guidelines!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withAlpha(80)),
                ),
                child: Text(
                  'Guidelines: ${zone.guidelines}',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddSafeZoneModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final latController = TextEditingController(text: '19.0760');
    final lngController = TextEditingController(text: '72.8777');
    final radiusController = TextEditingController(text: '200');
    final guidelinesController = TextEditingController(text: 'Assemble at center field. Bring emergency supplies.');
    String safetyLevel = 'high';
    final repo = context.read<FacilitiesRepository>();
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Designate Safe Zone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Zone Name *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description / Landmark'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: latController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Latitude *'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter latitude' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: lngController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Longitude *'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter longitude' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: safetyLevel,
                    decoration: const InputDecoration(labelText: 'Safety Level'),
                    items: const [
                      DropdownMenuItem(value: 'high', child: Text('High (Permanent Structure / High Ground)')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium (Temporary Open Ground)')),
                    ],
                    onChanged: (v) => safetyLevel = v!,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: radiusController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Safe Radius (meters)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: guidelinesController,
                    decoration: const InputDecoration(labelText: 'Assembly Guidelines'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final now = DateUtilsHelper.nowUtcIso();
                      final zone = SafeZoneModel(
                        id: const Uuid().v4(),
                        name: nameController.text.trim(),
                        description: descController.text.trim(),
                        latitude: double.parse(latController.text.trim()),
                        longitude: double.parse(lngController.text.trim()),
                        safetyLevel: safetyLevel,
                        radiusMeters: double.tryParse(radiusController.text.trim()) ?? 100.0,
                        guidelines: guidelinesController.text.trim(),
                        createdAt: now,
                        updatedAt: now,
                      );
                      await repo.addSafeZone(zone);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        setState(() {});
                        messenger.showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.green,
                            content: Text('Safe zone designated in local database!'),
                          ),
                        );
                      }
                    },
                    child: const Text('DESIGNATE SAFE ZONE'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
