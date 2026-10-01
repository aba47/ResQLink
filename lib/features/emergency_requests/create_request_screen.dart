import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../data/local/dao/user_dao.dart';
import '../../data/repositories/emergency_repository.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  String _requestType = 'rescue';
  String _priority = AppConstants.priorityCritical;
  int _peopleCount = 1;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _prefillUser();
  }

  Future<void> _prefillUser() async {
    final user = await UserDao().getActiveUser();
    if (user != null && mounted) {
      setState(() {
        _nameController.text = user.name;
        if (user.phone != null && user.phone != 'N/A') {
          _phoneController.text = user.phone!;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _descController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final repo = context.read<EmergencyRepository>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      double? lat = double.tryParse(_latController.text.trim());
      double? lng = double.tryParse(_lngController.text.trim());

      await repo.createEmergencyRequest(
        userName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        requestType: _requestType,
        priority: _priority,
        description: _descController.text.trim(),
        location: _locationController.text.trim(),
        peopleCount: _peopleCount,
        latitude: lat,
        longitude: lng,
      );

      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Emergency request recorded locally and added to sync queue!'),
        ),
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Emergency Request'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Offline Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.offline_bolt, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '100% Offline Capability: Stored locally in SQLite and synchronized when network returns.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Name *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
                ),
                const SizedBox(height: 14),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone *',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter phone' : null,
                ),
                const SizedBox(height: 14),

                // Request Type
                DropdownButtonFormField<String>(
                  initialValue: _requestType,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Type *',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'rescue', child: Text('Rescue Extraction')),
                    DropdownMenuItem(value: 'medical', child: Text('Medical Emergency')),
                    DropdownMenuItem(value: 'food_water', child: Text('Food & Clean Water Supply')),
                    DropdownMenuItem(value: 'evacuation', child: Text('Evacuation Aid')),
                    DropdownMenuItem(value: 'shelter', child: Text('Temporary Shelter Need')),
                    DropdownMenuItem(value: 'other', child: Text('Other Emergency')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _requestType = v);
                  },
                ),
                const SizedBox(height: 14),

                // Priority
                DropdownButtonFormField<String>(
                  initialValue: _priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority Level *',
                    prefixIcon: Icon(Icons.warning),
                  ),
                  items: const [
                    DropdownMenuItem(value: AppConstants.priorityCritical, child: Text('CRITICAL (Immediate Danger to Life)')),
                    DropdownMenuItem(value: AppConstants.priorityHigh, child: Text('HIGH (Urgent)')),
                    DropdownMenuItem(value: AppConstants.priorityMedium, child: Text('MEDIUM (Moderate)')),
                    DropdownMenuItem(value: AppConstants.priorityLow, child: Text('LOW (Non-immediate)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _priority = v);
                  },
                ),
                const SizedBox(height: 14),

                // People count
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Number of People Affected / Trapped:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _peopleCount > 1 ? () => setState(() => _peopleCount--) : null,
                    ),
                    Text(
                      '$_peopleCount',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setState(() => _peopleCount++),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Location
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location / Landmark *',
                    hintText: 'e.g. Near St. Mary Church, House 42, Flooded Street',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please specify location' : null,
                ),
                const SizedBox(height: 14),

                // Optional Coordinates
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Latitude (Optional)',
                          hintText: 'e.g. 19.0760',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Longitude (Optional)',
                          hintText: 'e.g. 72.8777',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Description
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Detailed Situation Description *',
                    hintText: 'State water depth, injuries, trapped children/elderly, special medical needs...',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please describe the emergency' : null,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                          'RECORD EMERGENCY REQUEST',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
