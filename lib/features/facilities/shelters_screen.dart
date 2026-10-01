import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/local/models/shelter_model.dart';
import '../../data/repositories/facilities_repository.dart';
import '../../shared/widgets/status_badge.dart';

class SheltersScreen extends StatefulWidget {
  const SheltersScreen({super.key});

  @override
  State<SheltersScreen> createState() => _SheltersScreenState();
}

class _SheltersScreenState extends State<SheltersScreen> {
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FacilitiesRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Relief Shelters'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddShelterModal(context),
        icon: const Icon(Icons.add_home_work),
        label: const Text('Register Shelter'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('all', 'All Shelters'),
                const SizedBox(width: 8),
                _buildFilterChip('open', 'Open'),
                const SizedBox(width: 8),
                _buildFilterChip('full', 'Full / At Capacity'),
                const SizedBox(width: 8),
                _buildFilterChip('closed', 'Closed'),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<ShelterModel>>(
              future: repo.getShelters(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allShelters = snapshot.data ?? [];
                final filtered = allShelters.where((s) {
                  if (_filterStatus == 'all') return true;
                  return s.status.toLowerCase() == _filterStatus.toLowerCase();
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.night_shelter_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'No Shelters In This View',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap "Register Shelter" to add new safe refugee locations.',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final shelter = filtered[index];
                    return _buildShelterCard(context, shelter);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filterStatus == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _filterStatus = key);
      },
    );
  }

  Widget _buildShelterCard(BuildContext context, ShelterModel shelter) {
    final occupancyPercent = shelter.capacity > 0
        ? (shelter.currentOccupancy / shelter.capacity).clamp(0.0, 1.0)
        : 0.0;

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
                    shelter.name,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                StatusBadge(label: shelter.status),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    shelter.address,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Occupancy Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Occupancy: ${shelter.currentOccupancy} / ${shelter.capacity}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Available: ${shelter.availableCapacity}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: shelter.availableCapacity > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: occupancyPercent,
              backgroundColor: Colors.grey[200],
              color: occupancyPercent > 0.9 ? Colors.red : (occupancyPercent > 0.7 ? Colors.orange : Colors.green),
            ),
            if (shelter.facilities != null && shelter.facilities!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Facilities: ${shelter.facilities}',
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
            ],
            if (shelter.contactPhone != null && shelter.contactPhone!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Contact: ${shelter.contactPerson ?? ""} (${shelter.contactPhone})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddShelterModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final capacityController = TextEditingController(text: '100');
    final occupancyController = TextEditingController(text: '0');
    final contactController = TextEditingController();
    final phoneController = TextEditingController();
    final facilitiesController = TextEditingController(text: 'Water, Food, Blankets, Medical Aid');
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
                  const Text('Register Safe Relief Shelter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Shelter Name *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address / Landmark *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter address' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: capacityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Total Capacity *'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter capacity' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: occupancyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Current Occupancy'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: contactController,
                          decoration: const InputDecoration(labelText: 'Contact Person'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Phone'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: facilitiesController,
                    decoration: const InputDecoration(labelText: 'Available Facilities'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final now = DateUtilsHelper.nowUtcIso();
                      final shelter = ShelterModel(
                        id: const Uuid().v4(),
                        name: nameController.text.trim(),
                        address: addressController.text.trim(),
                        capacity: int.tryParse(capacityController.text.trim()) ?? 100,
                        currentOccupancy: int.tryParse(occupancyController.text.trim()) ?? 0,
                        contactPerson: contactController.text.trim(),
                        contactPhone: phoneController.text.trim(),
                        facilities: facilitiesController.text.trim(),
                        status: 'open',
                        createdAt: now,
                        updatedAt: now,
                      );
                      await repo.addShelter(shelter);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        setState(() {});
                        messenger.showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.green,
                            content: Text('Shelter recorded in local database!'),
                          ),
                        );
                      }
                    },
                    child: const Text('REGISTER SHELTER'),
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
