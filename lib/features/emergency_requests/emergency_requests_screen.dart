import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/local/models/emergency_request_model.dart';
import '../../data/repositories/emergency_repository.dart';
import '../../shared/widgets/status_badge.dart';
import 'create_request_screen.dart';
import 'request_detail_screen.dart';

class EmergencyRequestsScreen extends StatefulWidget {
  const EmergencyRequestsScreen({super.key});

  @override
  State<EmergencyRequestsScreen> createState() => _EmergencyRequestsScreenState();
}

class _EmergencyRequestsScreenState extends State<EmergencyRequestsScreen> {
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<EmergencyRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Assistance Requests'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
          );
          if (created == true) {
            setState(() {});
          }
        },
        icon: const Icon(Icons.add_alert),
        label: const Text('New Request'),
        backgroundColor: AppConstants.priorityCritical == 'CRITICAL' ? Colors.red : Colors.orange,
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildStatusChip('all', 'All Requests'),
                const SizedBox(width: 8),
                _buildStatusChip(AppConstants.statusRequested, 'Requested'),
                const SizedBox(width: 8),
                _buildStatusChip(AppConstants.statusAccepted, 'Accepted'),
                const SizedBox(width: 8),
                _buildStatusChip(AppConstants.statusTeamAssigned, 'Team Assigned'),
                const SizedBox(width: 8),
                _buildStatusChip(AppConstants.statusInProgress, 'In Progress'),
                const SizedBox(width: 8),
                _buildStatusChip(AppConstants.statusCompleted, 'Completed'),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<EmergencyRequestModel>>(
              future: repo.getAllRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final requests = snapshot.data ?? [];
                final filtered = requests.where((r) {
                  if (_selectedStatus == 'all') return true;
                  return r.status.toLowerCase() == _selectedStatus.toLowerCase();
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'No Emergency Requests',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedStatus == 'all'
                                ? 'No requests filed locally yet. Tap "New Request" to create one.'
                                : 'No requests currently in "$_selectedStatus" status.',
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
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final req = filtered[index];
                    return _buildRequestCard(context, req);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String key, String label) {
    final isSelected = _selectedStatus == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedStatus = key);
      },
    );
  }

  Widget _buildRequestCard(BuildContext context, EmergencyRequestModel req) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RequestDetailScreen(requestId: req.id),
            ),
          );
          if (mounted) setState(() {});
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
                  StatusBadge(label: req.requestType.toUpperCase()),
                  Row(
                    children: [
                      StatusBadge(label: req.priority),
                      const SizedBox(width: 6),
                      StatusBadge(label: req.status),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                req.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 15, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${req.userName} (${req.phone})',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  const Icon(Icons.group_outlined, size: 15, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${req.peopleCount} person(s)',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 15, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      req.location,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  Text(
                    DateUtilsHelper.formatDisplay(req.createdAt),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
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
