import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/api_client.dart';
import '../../booking/presentation/create_booking_screen.dart';

class ProfessionalSearchScreen extends StatefulWidget {
  const ProfessionalSearchScreen({super.key});

  @override
  State<ProfessionalSearchScreen> createState() =>
      _ProfessionalSearchScreenState();
}

class _ProfessionalSearchScreenState extends State<ProfessionalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String selectedFilter = 'All';
  final List<String> filters = [
    'All',
    'doctors',
    'lawyers',
    'tutors',
    'therapists',
    'technicians',
  ];

  List<dynamic> professionals = [];
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadProfessionals();
  }

  Future<void> _loadProfessionals() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final data = await ApiClient.searchProfessionals(
        professionType: selectedFilter == 'All' ? null : selectedFilter,
        q: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

      final filtered = data.where((prof) {
        final status = prof['status'] as String?;
        return status == 'APPROVED' || status == 'ACTIVE';
      }).toList();

      setState(() {
        professionals = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading professionals: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(title: const Text('Search Professionals')),
      body: Column(
        children: [
          // Search + filter area
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                _buildSearchField(),
                const SizedBox(height: 12),
                _buildFilterChips(),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text('Failed to load professionals'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadProfessionals,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : professionals.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: AppTheme.textLight,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No professionals found',
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadProfessionals,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: professionals.length,
                      itemBuilder: (context, index) {
                        final pro = professionals[index];
                        return _buildProfessionalCard(pro);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: (_) => _loadProfessionals(),
        decoration: InputDecoration(
          hintText: 'Search by name, category, or city',
          hintStyle: const TextStyle(color: AppTheme.textLight),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textLight),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textLight),
                  onPressed: () {
                    _searchController.clear();
                    _loadProfessionals();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final displayName = filter == 'All'
              ? 'All'
              : filter[0].toUpperCase() + filter.substring(1);
          final isSelected = selectedFilter == filter;

          return ChoiceChip(
            label: Text(displayName),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                selectedFilter = filter;
              });
              _loadProfessionals();
            },
            backgroundColor: Colors.white,
            selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
            labelStyle: TextStyle(
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textDark,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfessionalCard(Map<String, dynamic> pro) {
    final String name = pro['user']?['name'] ?? 'Unknown';
    final String title = pro['title'] ?? '';
    final String professionType = pro['professionType'] ?? '';
    final String city = pro['city'] ?? '';
    final int fee = pro['baseFee'] ?? 0;
    final String mode = pro['consultationMode'] ?? 'both';
    final String categoryName = pro['ProfessionalCategory']?['name'] ?? '';

    final Color modeColor = mode == 'online'
        ? AppTheme.primaryBlue
        : mode == 'offline'
        ? AppTheme.primaryGreen
        : AppTheme.darkBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title.isNotEmpty ? title : '$professionType • $categoryName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppTheme.textLight,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        city,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Mode pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: modeColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    mode[0].toUpperCase() + mode.substring(1),
                    style: TextStyle(
                      fontSize: 11,
                      color: modeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Fee and button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹$fee',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const Text(
                'per session',
                style: TextStyle(fontSize: 11, color: AppTheme.textLight),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateBookingScreen(professional: pro),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Book',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
