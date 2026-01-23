import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SavedProfessionalsScreen extends StatefulWidget {
  const SavedProfessionalsScreen({super.key});

  @override
  State<SavedProfessionalsScreen> createState() => _SavedProfessionalsScreenState();
}

class _SavedProfessionalsScreenState extends State<SavedProfessionalsScreen> {
  // TODO: Fetch saved professionals from API
  final List<Map<String, dynamic>> _savedProfessionals = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Professionals'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _savedProfessionals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved professionals',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the bookmark icon on any professional\nto save them for quick access',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _savedProfessionals.length,
              itemBuilder: (context, index) {
                final professional = _savedProfessionals[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: professional['profileImage'] != null
                          ? NetworkImage(professional['profileImage'])
                          : null,
                      child: professional['profileImage'] == null
                          ? Text(professional['businessName'][0].toUpperCase())
                          : null,
                    ),
                    title: Text(professional['businessName']),
                    subtitle: Text(professional['category']),
                    trailing: IconButton(
                      icon: const Icon(Icons.bookmark, color: AppTheme.primaryBlue),
                      onPressed: () {
                        // TODO: Remove from saved
                        setState(() => _savedProfessionals.removeAt(index));
                      },
                    ),
                    onTap: () {
                      // TODO: Navigate to professional detail
                    },
                  ),
                );
              },
            ),
    );
  }
}
