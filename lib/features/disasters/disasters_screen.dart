import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/local/models/disaster_model.dart';
import '../../data/repositories/disaster_repository.dart';
import '../../shared/widgets/status_badge.dart';
import 'disaster_detail_screen.dart';

class DisastersScreen extends StatefulWidget {
  const DisastersScreen({super.key});

  @override
  State<DisastersScreen> createState() => _DisastersScreenState();
}

class _DisastersScreenState extends State<DisastersScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<DisasterRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disasters & Emergencies'),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('all', 'All Incidents'),
                const SizedBox(width: 8),
                _buildFilterChip('active', 'Active Disasters'),
                const SizedBox(width: 8),
                _buildFilterChip('critical', 'Critical Severity'),
                const SizedBox(width: 8),
                _buildFilterChip('flood', 'Floods'),
                const SizedBox(width: 8),
                _buildFilterChip('earthquake', 'Earthquakes'),
                const SizedBox(width: 8),
                _buildFilterChip('cyclone', 'Cyclones'),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<DisasterModel>>(
              future: repo.getAllDisasters(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDisasters = snapshot.data ?? [];
                final filtered = allDisasters.where((d) {
                  if (_selectedFilter == 'all') return true;
                  if (_selectedFilter == 'active') return d.status.toLowerCase() == 'active';
                  if (_selectedFilter == 'critical') return d.severity.toLowerCase() == 'critical';
                  return d.type.toLowerCase() == _selectedFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'No Disasters In This Category',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All synchronized local disaster events are up to date.',
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
                    final disaster = filtered[index];
                    return _buildDisasterCard(context, disaster);
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
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = key);
      },
    );
  }

  Widget _buildDisasterCard(BuildContext context, DisasterModel disaster) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DisasterDetailScreen(disaster: disaster),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 10),
              Text(
                disaster.title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      disaster.location,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reported: ${DateUtilsHelper.formatDisplay(disaster.reportedAt)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  Text(
                    'Status: ${disaster.status.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: disaster.status.toLowerCase() == 'active' ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
