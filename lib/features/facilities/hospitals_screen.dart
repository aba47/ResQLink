import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/local/models/hospital_model.dart';
import '../../data/repositories/facilities_repository.dart';
import '../../shared/widgets/status_badge.dart';

class HospitalsScreen extends StatefulWidget {
  const HospitalsScreen({super.key});

  @override
  State<HospitalsScreen> createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends State<HospitalsScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FacilitiesRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospitals & Medical Centers'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHospitalModal(context),
        icon: const Icon(Icons.local_hospital),
        label: const Text('Add Facility'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<HospitalModel>>(
        future: repo.getHospitals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final hospitals = snapshot.data ?? [];

          if (hospitals.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_hospital_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'No Hospitals Registered',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap "Add Facility" to record local medical posts or health centers.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: hospitals.length,
            itemBuilder: (context, index) {
              final h = hospitals[index];
              return _buildHospitalCard(context, h);
            },
          );
        },
      ),
    );
  }

  Widget _buildHospitalCard(BuildContext context, HospitalModel h) {
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
                    h.name,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                StatusBadge(label: h.status),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    h.address,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatPill('General Beds', '${h.availableBeds}/${h.totalBeds}', Colors.blue),
                const SizedBox(width: 8),
                _buildStatPill('ICU Beds', '${h.icuBedsAvailable}', Colors.red),
                const SizedBox(width: 8),
                _buildStatPill('Blood Units', '${h.bloodUnitsAvailable}', Colors.deepOrange),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.phone_in_talk, size: 16, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  'Emergency Desk: ${h.emergencyContact}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _showAddHospitalModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final totalBedsController = TextEditingController(text: '50');
    final availableBedsController = TextEditingController(text: '20');
    final icuController = TextEditingController(text: '5');
    final bloodController = TextEditingController(text: '15');
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
                  const Text('Add Hospital / Medical Center', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Facility Name *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address / Landmark *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter address' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Emergency Helpline / Desk *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter emergency phone' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: totalBedsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Total Beds'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: availableBedsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Available Beds'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: icuController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'ICU Beds'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: bloodController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Blood Units Avail.'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final now = DateUtilsHelper.nowUtcIso();
                      final hospital = HospitalModel(
                        id: const Uuid().v4(),
                        name: nameController.text.trim(),
                        address: addressController.text.trim(),
                        emergencyContact: phoneController.text.trim(),
                        totalBeds: int.tryParse(totalBedsController.text.trim()) ?? 0,
                        availableBeds: int.tryParse(availableBedsController.text.trim()) ?? 0,
                        icuBedsAvailable: int.tryParse(icuController.text.trim()) ?? 0,
                        bloodUnitsAvailable: int.tryParse(bloodController.text.trim()) ?? 0,
                        status: 'operational',
                        createdAt: now,
                        updatedAt: now,
                      );
                      await repo.addHospital(hospital);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        setState(() {});
                        messenger.showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.green,
                            content: Text('Hospital added to local database!'),
                          ),
                        );
                      }
                    },
                    child: const Text('SAVE FACILITY'),
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
