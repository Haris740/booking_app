import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/api_client.dart';
import '../../../services/image_helper.dart';

class BecomeProfessionalScreen extends StatefulWidget {
  const BecomeProfessionalScreen({super.key});

  @override
  State<BecomeProfessionalScreen> createState() =>
      _BecomeProfessionalScreenState();
}

class _BecomeProfessionalScreenState extends State<BecomeProfessionalScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _feeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  // State
  List<dynamic> _categories = [];
  int? _selectedCategoryId;
  String? _selectedProfessionType;
  String _consultationMode = 'BOTH';
  String _bookingType = 'BOTH';
  final List<String> _tags = [];
  String? _proofImage;

  bool _isLoadingCategories = true;
  bool _isGettingLocation = false;
  bool _isUploadingProof = false;
  bool _isSubmitting = false;

  final int _maxTags = 5;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await ApiClient.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: ${e.toString()}'),
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

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ?? place.subAdministrativeArea ?? 'Unknown';

        setState(() {
          _cityController.text = city;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location detected: $city'),
              backgroundColor: AppTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  Future<void> _uploadProof() async {
    setState(() => _isUploadingProof = true);

    try {
      final base64Image = await ImageHelper.pickAndCropImage(context);

      if (base64Image != null && mounted) {
        setState(() {
          _proofImage = base64Image;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Document uploaded successfully'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingProof = false);
      }
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty) return;

    if (_tags.length >= _maxTags) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum $_maxTags tags allowed'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (_tags.contains(tag)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tag already added'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a category'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ApiClient.applyProfessional(
        title: _titleController.text.trim(),
        professionType: _selectedProfessionType!,
        categorySlug: _selectedProfessionType!,
        categoryId: _selectedCategoryId!,
        about: _aboutController.text.trim(),
        city: _cityController.text.trim(),
        consultationMode: _consultationMode,
        baseFee: int.parse(_feeController.text.trim()),
        yearsExperience: int.parse(_experienceController.text.trim()),
        bookingType: _bookingType,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        proof: _proofImage,
        tags: _tags.isEmpty ? null : _tags,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '✓ Application submitted successfully!\nYou\'ll be notified after admin approval.',
            ),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(title: const Text('Become a Professional')),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 24),

                    // Category Selection
                    _buildSectionTitle('Professional Category'),
                    const SizedBox(height: 12),
                    _buildCategorySelector(),
                    const SizedBox(height: 24),

                    // Title
                    _buildSectionTitle('Profile Title'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _titleController,
                      label: 'Professional Title',
                      hint: 'e.g. Senior Cardiologist, Civil Lawyer',
                      icon: Icons.badge_outlined,
                      validator: (value) =>
                          value?.trim().isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),

                    // About
                    _buildSectionTitle('About Your Service'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _aboutController,
                      label: 'Description',
                      hint: 'Describe your expertise and services',
                      icon: Icons.description_outlined,
                      maxLines: 4,
                      validator: (value) =>
                          value?.trim().isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),

                    // Experience & Fee Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Experience'),
                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _experienceController,
                                label: 'Years',
                                hint: '5',
                                icon: Icons.timeline_outlined,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value?.trim().isEmpty ?? true) {
                                    return 'Required';
                                  }
                                  if (int.tryParse(value!) == null) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Fee (₹)'),
                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _feeController,
                                label: 'Amount',
                                hint: '500',
                                icon: Icons.currency_rupee_outlined,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value?.trim().isEmpty ?? true) {
                                    return 'Required';
                                  }
                                  if (int.tryParse(value!) == null) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // City
                    _buildSectionTitle('City'),
                    const SizedBox(height: 12),
                    _buildCityField(),
                    const SizedBox(height: 24),

                    // Address
                    _buildSectionTitle('Address/Clinic (Optional)'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'e.g. MG Road, Near City Hospital',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // Consultation Mode
                    _buildSectionTitle('Consultation Mode'),
                    const SizedBox(height: 12),
                    _buildModeSelector(),
                    const SizedBox(height: 24),

                    // Booking Type
                    _buildSectionTitle('Booking Type'),
                    const SizedBox(height: 12),
                    _buildBookingTypeSelector(),
                    const SizedBox(height: 24),

                    // Tags
                    _buildSectionTitle('Service Tags (Max $_maxTags)'),
                    const SizedBox(height: 12),
                    _buildTagInput(),
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildTagsList(),
                    ],
                    const SizedBox(height: 24),

                    // Proof Upload
                    _buildSectionTitle('Verification Document'),
                    const SizedBox(height: 8),
                    Text(
                      'Upload license, certificate, or ID proof',
                      style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                    ),
                    const SizedBox(height: 12),
                    _buildProofUpload(),
                    const SizedBox(height: 32),

                    // Submit Button
                    _buildSubmitButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.workspace_premium_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Submit your application to become a verified professional on our platform',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<int>(
        initialValue: _selectedCategoryId,
        decoration: InputDecoration(
          hintText: 'Select your profession',
          prefixIcon: const Icon(
            Icons.work_outline,
            color: AppTheme.primaryBlue,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        items: _categories.map((category) {
          return DropdownMenuItem<int>(
            value: category['id'],
            child: Text(category['name']),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCategoryId = value;
            final category = _categories.firstWhere((c) => c['id'] == value);
            _selectedProfessionType = category['slug'];
          });
        },
        validator: (value) => value == null ? 'Please select a category' : null,
      ),
    );
  }

  Widget _buildCityField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: _cityController,
        decoration: InputDecoration(
          labelText: 'City',
          hintText: 'Enter your city',
          prefixIcon: const Icon(
            Icons.location_city_outlined,
            color: AppTheme.primaryGreen,
          ),
          suffixIcon: _isGettingLocation
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryBlue,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.my_location, color: AppTheme.primaryBlue),
                  onPressed: _getCurrentLocation,
                  tooltip: 'Use current location',
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        validator: (value) => value?.trim().isEmpty ?? true ? 'Required' : null,
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        _buildModeChip('ONLINE', 'Online', Icons.videocam),
        const SizedBox(width: 8),
        _buildModeChip('OFFLINE', 'Offline', Icons.place),
        const SizedBox(width: 8),
        _buildModeChip('BOTH', 'Both', Icons.all_inclusive),
      ],
    );
  }

  Widget _buildModeChip(String value, String label, IconData icon) {
    final isSelected = _consultationMode == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _consultationMode = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textLight,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingTypeSelector() {
    return Column(
      children: [
        _buildBookingTypeOption(
          'TOKEN',
          'Token Based',
          'Queue system with token numbers',
        ),
        const SizedBox(height: 8),
        _buildBookingTypeOption(
          'TIMESLOT',
          'Time Slot',
          'Specific appointment times',
        ),
        const SizedBox(height: 8),
        _buildBookingTypeOption('BOTH', 'Both', 'Allow both methods'),
      ],
    );
  }

  Widget _buildBookingTypeOption(String value, String title, String subtitle) {
    final isSelected = _bookingType == value;
    return InkWell(
      onTap: () => setState(() => _bookingType = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Token System Option
            InkWell(
              onTap: () => setState(() => _bookingType = 'TOKEN'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _bookingType == 'TOKEN'
                      ? AppTheme.primaryBlue.withValues(alpha: 0.08)
                      : Colors.transparent,
                  border: Border.all(
                    color: _bookingType == 'TOKEN'
                        ? AppTheme.primaryBlue
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _bookingType == 'TOKEN'
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: _bookingType == 'TOKEN'
                          ? AppTheme.primaryBlue
                          : Colors.grey.shade600,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Token System',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _bookingType == 'TOKEN'
                                  ? AppTheme.primaryBlue
                                  : AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Users get sequential tokens, wait in queue',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Time Slot Option
            InkWell(
              onTap: () => setState(() => _bookingType = 'TIMESLOT'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _bookingType == 'TIMESLOT'
                      ? AppTheme.primaryBlue.withValues(alpha: 0.08)
                      : Colors.transparent,
                  border: Border.all(
                    color: _bookingType == 'TIMESLOT'
                        ? AppTheme.primaryBlue
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _bookingType == 'TIMESLOT'
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: _bookingType == 'TIMESLOT'
                          ? AppTheme.primaryBlue
                          : Colors.grey.shade600,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time Slot Booking',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _bookingType == 'TIMESLOT'
                                  ? AppTheme.primaryBlue
                                  : AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Users book specific time slots in advance',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTagInput() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _tagController,
              decoration: InputDecoration(
                hintText: 'Add a tag (e.g. Home visit, Emergency)',
                prefixIcon: const Icon(
                  Icons.local_offer_outlined,
                  color: AppTheme.primaryGreen,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onSubmitted: (_) => _addTag(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: _addTag,
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Add tag',
          ),
        ),
      ],
    );
  }

  Widget _buildTagsList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tags.map((tag) {
        return Chip(
          label: Text(tag),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () => _removeTag(tag),
          backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
          labelStyle: TextStyle(
            color: AppTheme.primaryGreen,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppTheme.primaryGreen),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProofUpload() {
    return InkWell(
      onTap: _isUploadingProof ? null : _uploadProof,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _proofImage != null
              ? AppTheme.primaryGreen.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _proofImage != null
                ? AppTheme.primaryGreen
                : Colors.grey.shade300,
            width: _proofImage != null ? 2 : 1,
            style: _proofImage == null ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: _isUploadingProof
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryBlue,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Uploading...'),
                ],
              )
            : Row(
                children: [
                  Icon(
                    _proofImage != null
                        ? Icons.check_circle
                        : Icons.upload_file,
                    color: _proofImage != null
                        ? AppTheme.primaryGreen
                        : AppTheme.primaryBlue,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _proofImage != null
                              ? 'Document Uploaded'
                              : 'Upload Document',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _proofImage != null
                                ? AppTheme.primaryGreen
                                : AppTheme.textDark,
                          ),
                        ),
                        Text(
                          _proofImage != null
                              ? 'Tap to change'
                              : 'License, certificate, or ID proof',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.textLight,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitApplication,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Submit Application',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _aboutController.dispose();
    _experienceController.dispose();
    _feeController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _tagController.dispose();
    super.dispose();
  }
}
