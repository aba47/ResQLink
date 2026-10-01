import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/local/models/disaster_report_model.dart';
import '../../data/repositories/disaster_repository.dart';
import '../../shared/widgets/status_badge.dart';

class DisasterReportsScreen extends StatefulWidget {
  const DisasterReportsScreen({super.key});

  @override
  State<DisasterReportsScreen> createState() => _DisasterReportsScreenState();
}

class _DisasterReportsScreenState extends State<DisasterReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = context.watch<DisasterRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disaster Incident Reports'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateReportSheet(context),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Report Incident'),
        backgroundColor: Colors.orange[800],
      ),
      body: FutureBuilder<List<DisasterReportModel>>(
        future: repo.getAllReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'No Incident Reports Filed',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap "Report Incident" below to record field conditions even while offline.',
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
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return _buildReportCard(context, report);
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, DisasterReportModel report) {
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
                StatusBadge(label: report.disasterType.toUpperCase()),
                Row(
                  children: [
                    StatusBadge(label: report.severity),
                    const SizedBox(width: 6),
                    StatusBadge(label: report.syncStatus),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              report.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              report.description,
              style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.3),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on, size: 15, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.location,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (report.casualtiesCount > 0) ...[
                  Text(
                    'Casualties: ${report.casualtiesCount}  ',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ],
                if (report.injuredCount > 0) ...[
                  Text(
                    'Injured: ${report.injuredCount}  ',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ],
                const Spacer(),
                Text(
                  DateUtilsHelper.formatDisplay(report.createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateReportSheet(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final locController = TextEditingController();
    final descController = TextEditingController();
    final casualtiesController = TextEditingController(text: '0');
    final injuredController = TextEditingController(text: '0');
    final disasterRepo = context.read<DisasterRepository>();
    final messenger = ScaffoldMessenger.of(context);

    String disasterType = 'flood';
    String severity = 'HIGH';

    await showModalBottomSheet(
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
                  const Text('File Disaster Incident Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Records local damage & casualties. Queued for offline sync.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Incident Title *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter title' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: disasterType,
                    decoration: const InputDecoration(labelText: 'Disaster Type'),
                    items: const [
                      DropdownMenuItem(value: 'flood', child: Text('Flooding / Flash Flood')),
                      DropdownMenuItem(value: 'earthquake', child: Text('Earthquake / Building Collapse')),
                      DropdownMenuItem(value: 'landslide', child: Text('Landslide / Mudflow')),
                      DropdownMenuItem(value: 'fire', child: Text('Wildfire / Structural Fire')),
                      DropdownMenuItem(value: 'cyclone', child: Text('Cyclone / Hurricane')),
                    ],
                    onChanged: (v) => disasterType = v!,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: severity,
                    decoration: const InputDecoration(labelText: 'Observed Severity'),
                    items: const [
                      DropdownMenuItem(value: 'CRITICAL', child: Text('Critical (Heavy Destruction)')),
                      DropdownMenuItem(value: 'HIGH', child: Text('High')),
                      DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                      DropdownMenuItem(value: 'LOW', child: Text('Minor')),
                    ],
                    onChanged: (v) => severity = v!,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: locController,
                    decoration: const InputDecoration(labelText: 'Location / Landmark *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter location' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: casualtiesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Casualties Count'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: injuredController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Injured Count'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Incident Description *',
                      hintText: 'Describe blocked roads, damaged utilities, bridges, electrical hazards...',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter description' : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      await disasterRepo.submitReport(
                        title: titleController.text.trim(),
                        disasterType: disasterType,
                        description: descController.text.trim(),
                        severity: severity,
                        location: locController.text.trim(),
                        casualtiesCount: int.tryParse(casualtiesController.text.trim()) ?? 0,
                        injuredCount: int.tryParse(injuredController.text.trim()) ?? 0,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        setState(() {});
                        messenger.showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.green,
                            content: Text('Disaster report recorded locally in SQLite & queued for sync!'),
                          ),
                        );
                      }
                    },
                    child: const Text('SUBMIT INCIDENT REPORT'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    titleController.dispose();
    locController.dispose();
    descController.dispose();
    casualtiesController.dispose();
    injuredController.dispose();
  }
}
