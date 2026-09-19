import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Service exception for image upload failures.
class CloudImageException implements Exception {
  final String message;
  const CloudImageException(this.message);

  @override
  String toString() => message;
}

/// Free cloud image hosting service integrating Cloudinary Unsigned Uploads.
/// Allows direct image uploads without requiring a backend server or a paid Firebase Blaze plan.
class CloudImageService {
  CloudImageService._();

  // Cloudinary credentials (Unsigned Upload Preset)
  // Users can customize these constants anytime with their personal Cloudinary credentials.
  static String cloudName = 'dkmv1b5z0';
  static String uploadPreset = 'bazaar_shodai_unsigned';

  /// Uploads an [XFile] (from ImagePicker) to Cloudinary via unsigned upload preset.
  /// Works across Android, iOS, and Web by reading bytes.
  /// Returns the permanent HTTPS secure URL of the hosted image.
  static Future<String> uploadImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      if (bytes.isEmpty) {
        throw const CloudImageException('Selected image is empty.');
      }

      // Check file size (e.g. limit to 10MB)
      if (bytes.lengthInBytes > 10 * 1024 * 1024) {
        throw const CloudImageException('Image size exceeds the 10MB limit. Please choose a smaller photo.');
      }

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);

      // Attach unsigned upload preset
      request.fields['upload_preset'] = uploadPreset;

      // Attach image file bytes
      final fileName = imageFile.name.isNotEmpty ? imageFile.name : 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      );
      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw const CloudImageException('Image upload timed out. Please check your internet connection.'),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final secureUrl = data['secure_url'] as String?;
        if (secureUrl != null && secureUrl.isNotEmpty) {
          return secureUrl;
        }
        throw const CloudImageException('Cloudinary did not return a valid secure URL.');
      } else {
        // Parse error message if available
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          final errorMsg = errorData['error']?['message'] ?? 'Upload failed with status ${response.statusCode}';
          throw CloudImageException('Upload failed: $errorMsg');
        } catch (e) {
          if (e is CloudImageException) rethrow;
          throw CloudImageException('Upload failed with status code ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is CloudImageException) rethrow;
      throw CloudImageException('Failed to upload image: ${e.toString()}');
    }
  }
}
