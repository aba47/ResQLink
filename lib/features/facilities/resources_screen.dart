import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/models/resource_model.dart';
import '../../data/repositories/facilities_repository.dart';
import '../../shared/widgets/status_badge.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FacilitiesRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Relief Resources'),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildCategoryChip('all', 'All Supplies'),
                const SizedBox(width: 8),
                _buildCategoryChip('food', 'Food Kits'),
                const SizedBox(width: 8),
                _buildCategoryChip('water', 'Drinking Water'),
                const SizedBox(width: 8),
                _buildCategoryChip('medicine', 'Medical Supplies'),
                const SizedBox(width: 8),
                _buildCategoryChip('equipment', 'Rescue Equipment'),
                const SizedBox(width: 8),
                _buildCategoryChip('blankets', 'Blankets / Warmth'),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<ResourceModel>>(
              future: repo.getResources(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final resources = snapshot.data ?? [];
                final filtered = resources.where((r) {
                  if (_selectedCategory == 'all') return true;
                  return r.category.toLowerCase() == _selectedCategory.toLowerCase();
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'No Resources In This Category',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Supply inventories are tracked and updated locally or via peer sync.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final resource = filtered[index];
                    return _buildResourceCard(context, resource);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedCategory = key);
      },
    );
  }

  Widget _buildResourceCard(BuildContext context, ResourceModel r) {
    IconData icon;
    Color color;

    switch (r.category.toLowerCase()) {
      case 'food':
        icon = Icons.restaurant;
        color = Colors.orange;
        break;
      case 'water':
        icon = Icons.water_drop;
        color = Colors.blue;
        break;
      case 'medicine':
        icon = Icons.medication;
        color = Colors.red;
        break;
      case 'equipment':
        icon = Icons.handyman;
        color = Colors.indigo;
        break;
      default:
        icon = Icons.inventory;
        color = Colors.teal;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Location: ${r.location}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quantity: ${r.quantity} ${r.unit}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
            StatusBadge(label: r.status),
          ],
        ),
      ),
    );
  }
}
