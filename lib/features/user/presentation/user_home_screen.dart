import 'package:booking_app/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../professional/presentation/become_professional_screen.dart';
import '../../professional/presentation/professional_dashboard_screen.dart';
import 'professional_search_screen.dart';
import 'profile_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../booking/presentation/my_bookings_screen.dart';
import '../../../services/image_helper.dart';
import 'notifications_screen.dart';
import 'saved_professionals_screen.dart';
import 'token_tracking_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  String userCity = 'Location';
  String userName = 'User';

  // NEW: Professional status and staff invitation states
  bool _showProfessionalOptions = true;
  String? _cannotApplyReason;
  bool _isLoadingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkProfessionalStatusAndInvitations();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'User';
      userCity = prefs.getString('userCity') ?? 'Location';
    });
  }

  /// NEW: Check if user can apply as professional and load staff invitations
  Future<void> _checkProfessionalStatusAndInvitations() async {
    setState(() => _isLoadingStatus = true);
    try {
      // Check if user can apply to be professional
      final canApplyRes = await ApiClient.canApplyProfessional();
      final canApply = canApplyRes['canApply'] == true;
      final reason = canApplyRes['reason'];

      // Load staff invitations
      final invitations = await ApiClient.getStaffInvitations();

      if (mounted) {
        setState(() {
          _showProfessionalOptions = canApply;
          _cannotApplyReason = reason;
        });

        // Show invitation dialog if any pending
        if (invitations.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showStaffInvitationDialog(invitations.first);
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking status/invitations: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingStatus = false);
      }
    }
  }

  /// NEW: Show booking staff invitation dialog
  void _showStaffInvitationDialog(Map<String, dynamic> invitation) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.badge, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Booking Staff Invitation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${invitation['professional']['user']['name']} (${invitation['professional']['title']}) has invited you to be their booking staff.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (invitation['message'] != null &&
                invitation['message'].isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  invitation['message'],
                  style: TextStyle(fontSize: 13, color: AppTheme.textDark),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _respondToStaffInvitation(invitation['id'], false),
            child: const Text('Decline', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => _respondToStaffInvitation(invitation['id'], true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  /// NEW: Respond to staff invitation
  Future<void> _respondToStaffInvitation(
    String invitationId,
    bool accept,
  ) async {
    Navigator.of(context).pop(); // Close dialog

    try {
      if (accept) {
        await ApiClient.acceptStaffInvitation(invitationId);
      } else {
        await ApiClient.rejectStaffInvitation(invitationId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept
                  ? 'Welcome to booking staff team!'
                  : 'Invitation declined.',
            ),
            backgroundColor: accept ? AppTheme.primaryGreen : Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Reload status - professional options will now be hidden
        await _checkProfessionalStatusAndInvitations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error responding: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Book Professionals'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppTheme.textDark,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          // REMOVE THE ListTile AND REPLACE WITH THIS IconButton:
          IconButton(
            icon: const Icon(Icons.business_center, color: AppTheme.textDark),
            tooltip: 'Professional Dashboard',
            onPressed: () async {
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                final user = await ApiClient.getMyProfile();

                if (mounted) Navigator.pop(context);

                bool isProfessional = false;
                bool isApproved = false;
                dynamic professionalId;
                Map<String, dynamic> professionalData = {};

                if (user['isProfessional'] == true) {
                  isProfessional = true;
                  professionalId = user['professionalId'] ?? user['id'];

                  final status = user['professionalStatus']
                      ?.toString()
                      .toUpperCase();
                  isApproved = status == 'APPROVED';
                }

                if (user['professional'] != null) {
                  isProfessional = true;

                  // FIX: Properly cast the professional data
                  final profData = user['professional'];
                  if (profData is Map) {
                    professionalData = Map<String, dynamic>.from(profData);
                  }

                  professionalId = professionalData['id'] ?? user['id'];

                  final status = professionalData['status']
                      ?.toString()
                      .toUpperCase();
                  isApproved = status == 'APPROVED';
                }

                if (isProfessional && isApproved) {
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfessionalDashboardScreen(
                          professionalId: professionalId.toString(),
                          professionalData:
                              professionalData, // Now properly typed
                        ),
                      ),
                    );
                  }
                } else {
                  String message = 'Professional access not available';
                  if (isProfessional && !isApproved) {
                    message =
                        'Your professional application is pending approval';
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(message)));
                  }
                }
              } catch (e, stackTrace) {
                debugPrint('❌ Error fetching professional data: $e');
                debugPrint('Stack trace: $stackTrace');

                if (mounted) {
                  Navigator.of(context, rootNavigator: true).pop();
                }

                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
          ),
          IconButton(
            icon: FutureBuilder<String?>(
              future: SharedPreferences.getInstance().then((prefs) async {
                try {
                  final user = await ApiClient.getMyProfile();
                  return user['profilePicture'] as String?;
                } catch (e) {
                  return null;
                }
              }),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final image = ImageHelper.base64ToImage(snapshot.data);
                  if (image != null) {
                    return CircleAvatar(
                      radius: 16,
                      child: ClipOval(child: image),
                    );
                  }
                }
                return const Icon(
                  Icons.account_circle_outlined,
                  color: AppTheme.textDark,
                );
              },
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ).then((_) => _loadUserData());
            },
          ),
        ],
      ),
      body: _isLoadingStatus
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with gradient
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting
                        Text(
                          'Hello, $userName 👋',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              userCity,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Search bar
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ProfessionalSearchScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.search, color: AppTheme.textLight),
                                SizedBox(width: 12),
                                Text(
                                  'Search professional, category, or service',
                                  style: TextStyle(
                                    color: AppTheme.textLight,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // MODIFIED: Only show "Are you a professional?" if allowed
                        if (_showProfessionalOptions) ...[
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const BecomeProfessionalScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.workspace_premium_outlined,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Are you a professional?\nTap here to offer your services.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.95,
                                        ),
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          // Show reason why professional options are hidden
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _cannotApplyReason ??
                                        'Professional options unavailable',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.4,
                          children: [
                            _buildQuickActionCard(
                              context,
                              'Book\nProfessional',
                              Icons.calendar_today_outlined,
                              AppTheme.blueGradient,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ProfessionalSearchScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildQuickActionCard(
                              context,
                              'My\nBookings',
                              Icons.list_alt_outlined,
                              AppTheme.greenGradient,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const MyBookingsScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildQuickActionCard(
                              context,
                              'Saved\nProfessionals',
                              Icons.favorite_border_rounded,
                              const LinearGradient(
                                colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                              ),
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SavedProfessionalsScreen(),
                                  ),
                                );
                              },
                            ),
                            // MODIFIED: Only show "Become Professional" if allowed
                            if (_showProfessionalOptions)
                              _buildQuickActionCard(
                                context,
                                'Become\nProfessional',
                                Icons.workspace_premium_outlined,
                                const LinearGradient(
                                  colors: [
                                    Color(0xFF10B981),
                                    Color(0xFF059669),
                                  ],
                                ),
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const BecomeProfessionalScreen(),
                                    ),
                                  );
                                },
                              )
                            else
                              _buildQuickActionCard(
                                context,
                                'Track\nToken',
                                Icons.confirmation_number_outlined,
                                const LinearGradient(
                                  colors: [
                                    Color(0xFF10B981),
                                    Color(0xFF059669),
                                  ],
                                ),
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const TokenTrackingScreen(),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Categories / specialties
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Popular Categories',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ProfessionalSearchScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'See All',
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 110,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildCategoryCard(
                                'Doctors',
                                Icons.medical_services_outlined,
                                AppTheme.primaryBlue,
                              ),
                              _buildCategoryCard(
                                'Lawyers',
                                Icons.gavel_outlined,
                                AppTheme.primaryGreen,
                              ),
                              _buildCategoryCard(
                                'Tutors',
                                Icons.menu_book_outlined,
                                AppTheme.darkBlue,
                              ),
                              _buildCategoryCard(
                                'Therapists',
                                Icons.psychology_alt_outlined,
                                AppTheme.darkGreen,
                              ),
                              _buildCategoryCard(
                                'Technicians',
                                Icons.handyman_outlined,
                                AppTheme.primaryBlue,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Keep existing helper methods unchanged
  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    LinearGradient gradient,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String name, IconData icon, Color color) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 26, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
