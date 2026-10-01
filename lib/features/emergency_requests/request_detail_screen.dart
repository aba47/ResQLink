import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/local/models/emergency_request_model.dart';
import '../../data/repositories/emergency_repository.dart';
import '../../shared/widgets/status_badge.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  EmergencyRequestModel? _request;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    final repo = context.read<EmergencyRepository>();
    final req = await repo.getRequestById(widget.requestId);
    if (mounted) {
      setState(() {
        _request = req;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String nextStatus, {String? team}) async {
    final repo = context.read<EmergencyRepository>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await repo.updateRequestStatus(widget.requestId, nextStatus, assignedTeam: team);
      await _loadRequest();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text('Status updated to $nextStatus & queued for sync!'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')),
      );
    }
  }

  void _promptAssignTeamAndProceed(String nextStatus) {
    final controller = TextEditingController(text: _request?.assignedTeam ?? 'NDRF Unit 1');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Response Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter team/vehicle identifier responsible for this rescue mission:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Team Name / Unit Code',
                hintText: 'e.g. NDRF Rescue Boat 4',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(nextStatus, team: controller.text.trim());
            },
            child: const Text('Confirm Assignment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Emergency Request Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_request == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Emergency Request Details')),
        body: const Center(child: Text('Request not found.')),
      );
    }

    final req = _request!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Request #${req.id.substring(0, 8)}'),
      ),
      bottomNavigationBar: _buildWorkflowActionBar(context, req),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Priority Header
            Card(
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
                    const SizedBox(height: 16),
                    Text(
                      req.description,
                      style: const TextStyle(fontSize: 16, height: 1.4, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Responder Workflow Progress Stepper
            const Text(
              'Rescue / Response Pipeline',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildPipelineVisualizer(req.status),
            const SizedBox(height: 20),

            // Requester Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Contact & Location Info', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.person, 'Contact Person', req.userName),
                    const SizedBox(height: 10),
                    _buildInfoRow(Icons.phone, 'Phone Number', req.phone),
                    const SizedBox(height: 10),
                    _buildInfoRow(Icons.group, 'People Affected', '${req.peopleCount} person(s)'),
                    const SizedBox(height: 10),
                    _buildInfoRow(Icons.location_on, 'Location', req.location),
                    if (req.latitude != null && req.longitude != null) ...[
                      const SizedBox(height: 10),
                      _buildInfoRow(Icons.map, 'Coordinates', '${req.latitude}, ${req.longitude}'),
                    ],
                    if (req.assignedTeam != null && req.assignedTeam!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildInfoRow(Icons.shield, 'Assigned Unit', req.assignedTeam!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Metadata Card
            Card(
              color: theme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Filed Locally At:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(DateUtilsHelper.formatDisplay(req.createdAt), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sync Status:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        StatusBadge(label: req.syncStatus),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPipelineVisualizer(String currentStatus) {
    final stages = [
      AppConstants.statusRequested,
      AppConstants.statusAccepted,
      AppConstants.statusTeamAssigned,
      AppConstants.statusInProgress,
      AppConstants.statusCompleted,
    ];

    final currentIndex = stages.indexOf(currentStatus);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(stages.length, (index) {
          final isDone = index <= currentIndex;
          final isCurrent = index == currentIndex;
          final name = stages[index];

          return Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isCurrent
                      ? Colors.orange
                      : (isDone ? Colors.green : Colors.grey[300]),
                  child: isDone
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text('${index + 1}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? Colors.black : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWorkflowActionBar(BuildContext context, EmergencyRequestModel req) {
    Widget actionButton;

    switch (req.status) {
      case AppConstants.statusRequested:
        actionButton = ElevatedButton.icon(
          onPressed: () => _updateStatus(AppConstants.statusAccepted),
          icon: const Icon(Icons.thumb_up),
          label: const Text('ACCEPT REQUEST'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
        );
        break;
      case AppConstants.statusAccepted:
        actionButton = ElevatedButton.icon(
          onPressed: () => _promptAssignTeamAndProceed(AppConstants.statusTeamAssigned),
          icon: const Icon(Icons.group_add),
          label: const Text('ASSIGN TEAM & DISPATCH'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[700]),
        );
        break;
      case AppConstants.statusTeamAssigned:
        actionButton = ElevatedButton.icon(
          onPressed: () => _updateStatus(AppConstants.statusInProgress),
          icon: const Icon(Icons.directions_run),
          label: const Text('MARK IN PROGRESS / RESCUE STARTED'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800]),
        );
        break;
      case AppConstants.statusInProgress:
        actionButton = ElevatedButton.icon(
          onPressed: () => _updateStatus(AppConstants.statusCompleted),
          icon: const Icon(Icons.check_circle),
          label: const Text('MARK RESCUE COMPLETED'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
        );
        break;
      case AppConstants.statusCompleted:
      default:
        actionButton = OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.done_all, color: Colors.green),
          label: const Text('RESCUE MISSION COMPLETED'),
        );
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: actionButton,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
