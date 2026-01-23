import 'package:flutter/material.dart';
import '../auth/presentation/login_screen.dart';
import '../user/presentation/user_home_screen.dart';
import '../professional/presentation/professional_dashboard_screen.dart';
import '../../services/api_client.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    final isLoggedIn = await ApiClient.isLoggedIn();
    debugPrint('🔐 Login status check: $isLoggedIn');

    if (!isLoggedIn) {
      _navigateToLogin();
      return;
    }

    try {
      // Decode token to check professional status
      await ApiClient.debugToken();

      // Fetch user profile
      final user = await ApiClient.getMyProfile();

      // Check if user is a professional
      if (user['isProfessional'] == true) {
        final status = user['professionalStatus'];

        if (status == 'APPROVED') {
          // Navigate to professional dashboard
          _navigateToProfessionalDashboard(user);
        } else if (status == 'PENDING') {
          // Show pending message, navigate to user home
          _navigateToUserHome(showPendingMessage: true);
        } else {
          // Not professional or rejected
          _navigateToUserHome();
        }
      } else {
        // Regular user
        _navigateToUserHome();
      }
    } catch (e) {
      debugPrint('❌ Profile fetch error: $e');

      if (e.toString().contains('Session expired')) {
        _navigateToLogin();
      } else {
        _navigateToUserHome();
      }
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToUserHome({bool showPendingMessage = false}) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const UserHomeScreen()),
    );

    if (showPendingMessage) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Your professional application is pending approval',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    }
  }

  void _navigateToProfessionalDashboard(Map<String, dynamic> user) {
    if (!mounted) return;

    // Extract and properly cast professional data
    final profData = user['professional'];
    Map<String, dynamic> professionalData = {};

    if (profData is Map) {
      professionalData = Map<String, dynamic>.from(profData);
    }

    final professionalId =
        user['professionalId'] ?? professionalData['id'] ?? user['id'];

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProfessionalDashboardScreen(
          professionalId: professionalId.toString(),
          professionalData: professionalData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Booking App',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
