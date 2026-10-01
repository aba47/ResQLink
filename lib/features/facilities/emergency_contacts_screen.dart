import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/local/models/emergency_contact_model.dart';
import '../../data/repositories/facilities_repository.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FacilitiesRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContactModal(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Contact'),
        backgroundColor: Colors.green[700],
      ),
      body: FutureBuilder<List<EmergencyContactModel>>(
        future: repo.getEmergencyContacts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final contacts = snapshot.data ?? [];

          if (contacts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.contact_phone_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'No Emergency Contacts',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Save family members, local ward leaders, or local doctors for rapid offline access.',
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
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return _buildContactCard(context, contact);
            },
          );
        },
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, EmergencyContactModel contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: contact.isPrimary ? Colors.red.withAlpha(30) : Colors.blue.withAlpha(30),
          child: Icon(
            contact.isPrimary ? Icons.star : Icons.person,
            color: contact.isPrimary ? Colors.red : Colors.blue,
          ),
        ),
        title: Row(
          children: [
            Text(
              contact.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (contact.isPrimary) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.withAlpha(80)),
                ),
                child: const Text('PRIMARY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red)),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${contact.relationship} • Phone: ${contact.phone}',
          style: TextStyle(color: Colors.grey[700], fontSize: 13),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.phone, color: Colors.green),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Dialing ${contact.name} at ${contact.phone}...')),
            );
          },
        ),
      ),
    );
  }

  void _showAddContactModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final relationController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    bool isPrimary = false;
    final repo = context.read<FacilitiesRepository>();
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
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
                      const Text('Add Emergency Contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name *'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: relationController,
                        decoration: const InputDecoration(labelText: 'Relationship (e.g. Parent, Doctor, Ward Member) *'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter relationship' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone Number *'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter phone' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email (Optional)'),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Set as Primary Emergency Contact'),
                        value: isPrimary,
                        onChanged: (val) => setModalState(() => isPrimary = val),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final now = DateUtilsHelper.nowUtcIso();
                          final contact = EmergencyContactModel(
                            id: const Uuid().v4(),
                            name: nameController.text.trim(),
                            relationship: relationController.text.trim(),
                            phone: phoneController.text.trim(),
                            email: emailController.text.trim(),
                            isPrimary: isPrimary,
                            createdAt: now,
                            updatedAt: now,
                          );
                          await repo.addContact(contact);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            setState(() {});
                            messenger.showSnackBar(
                              const SnackBar(
                                backgroundColor: Colors.green,
                                content: Text('Emergency contact saved locally!'),
                              ),
                            );
                          }
                        },
                        child: const Text('SAVE CONTACT'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
