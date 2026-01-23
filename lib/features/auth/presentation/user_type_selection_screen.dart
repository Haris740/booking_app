import 'package:flutter/material.dart';
import '../../user/presentation/user_home_screen.dart';
import '../../../core/theme/app_theme.dart';

class UserTypeSelectionScreen extends StatelessWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userTypes = [
      {
        'title': 'Patient User',
        'subtitle': 'Book appointments for yourself',
        'icon': Icons.person_outline_rounded,
        'gradient': AppTheme.blueGradient,
      },
      {
        'title': 'Relative / Family Member',
        'subtitle': 'Book for family members',
        'icon': Icons.family_restroom_outlined,
        'gradient': AppTheme.greenGradient,
      },
      {
        'title': 'Doctor',
        'subtitle': 'Manage appointments & patients',
        'icon': Icons.medical_services_outlined,
        'gradient': const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
        ),
      },
      {
        'title': 'Booking Staff',
        'subtitle': 'Manage clinic bookings',
        'icon': Icons.badge_outlined,
        'gradient': const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'I am a...',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select your role to continue',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 32),
            
            Expanded(
              child: ListView.builder(
                itemCount: userTypes.length,
                itemBuilder: (context, index) {
                  final userType = userTypes[index];
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserHomeScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: userType['gradient'] as LinearGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                userType['icon'] as IconData,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userType['title'] as String,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userType['subtitle'] as String,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 18,
                              color: AppTheme.textLight,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
