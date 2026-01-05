import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  // Pick and crop image
  static Future<String?> pickAndCropImage(BuildContext context) async {
    try {
      // Show source selection dialog
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return null;

      // Pick image
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile == null) return null;

      // Crop image to square
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: const Color(0xFF0EA5E9),
            toolbarWidgetColor: Colors.white,
            statusBarColor: const Color(0xFF0EA5E9),
            backgroundColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF0EA5E9),
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            resetAspectRatioEnabled: false,
          ),
        ],
        compressQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
        compressFormat: ImageCompressFormat.jpg,
      );

      if (croppedFile == null) return null;

      // Convert to base64
      final bytes = await File(croppedFile.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Return with data URI prefix
      return 'data:image/jpeg;base64,$base64Image';
    } catch (e) {
      debugPrint('Error picking/cropping image: $e');
      return null;
    }
  }

  // Convert base64 to Image widget
  static Image? base64ToImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    
    try {
      // Remove data URI prefix if present
      final base64Data = base64String.contains('base64,')
          ? base64String.split('base64,')[1]
          : base64String;
      
      return Image.memory(
        base64Decode(base64Data),
        fit: BoxFit.cover,
      );
    } catch (e) {
      debugPrint('Error decoding base64 image: $e');
      return null;
    }
  }
}
