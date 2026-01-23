import 'package:booking_app/services/api_client.dart';
import 'package:flutter/material.dart';

class ProfessionalStaffScreen extends StatefulWidget {
  final String professionalId; // pass from professional dashboard

  const ProfessionalStaffScreen({super.key, required this.professionalId});

  @override
  State<ProfessionalStaffScreen> createState() =>
      _ProfessionalStaffScreenState();
}

class _ProfessionalStaffScreenState extends State<ProfessionalStaffScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _inviting = false;
  bool _loading = true;
  List<dynamic> _staff = [];

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => _loading = true);
    try {
      final list = await ApiClient.getProfessionalStaff();
      if (!mounted) return;
      setState(() => _staff = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading staff: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _invite() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter phone number')));
      return;
    }
    setState(() => _inviting = true);
    try {
      await ApiClient.inviteStaff(
        phone: phone,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
      );
      _phoneController.clear();
      _messageController.clear();
      await _loadStaff();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invitation sent')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  Future<void> _removeStaff(String staffId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove staff'),
        content: const Text(
          'Are you sure you want to remove this staff member?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiClient.removeStaff(staffId);
      await _loadStaff();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking staff')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message (optional)',
                    prefixIcon: Icon(Icons.message_outlined),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _inviting ? null : _invite,
                    child: _inviting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send invitation'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _staff.isEmpty
                ? const Center(child: Text('No booking staff yet'))
                : ListView.builder(
                    itemCount: _staff.length,
                    itemBuilder: (context, index) {
                      final s = _staff[index];
                      final u = s['user'] ?? {};
                      return ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(u['name'] ?? 'Unknown'),
                        subtitle: Text(u['phone'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeStaff(s['id'] as String),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
