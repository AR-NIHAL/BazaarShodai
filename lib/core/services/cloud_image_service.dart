import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Service exception for image upload failures.
class CloudImageException implements Exception {
  final String message;
  const CloudImageException(this.message);

  @override
  String toString() => message;
}

/// Free cloud image hosting service integrating ImgBB API.
/// Seamlessly loads from .env, dart-define, or developer key.
class CloudImageService {
  CloudImageService._();

  // Active ImgBB API Key (used directly & as fallback when .env is unavailable on Web)
  static const String _defaultApiKey = '0f367f1262527e7d56c8991142ede17f';

  static String _manualKey = '';

  /// Optional manual key setter for unit testing or overrides
  static set manualApiKey(String key) => _manualKey = key;

  /// Retrieves the ImgBB API key:
  /// 1. From optional manual key override
  /// 2. From local .env file (`IMGBB_API_KEY`)
  /// 3. From compile-time dart-define environment
  /// 4. From default developer key fallback
  static String get imgbbApiKey {
    if (_manualKey.trim().isNotEmpty) {
      return _manualKey.trim();
    }

    try {
      if (dotenv.isInitialized) {
        final envKey = dotenv.env['IMGBB_API_KEY']?.trim();
        if (envKey != null && envKey.isNotEmpty && envKey != 'your_imgbb_api_key_here') {
          return envKey;
        }
      }
    } catch (_) {
      // Ignored if dotenv is not loaded
    }

    const dartDefineKey = String.fromEnvironment('IMGBB_API_KEY');
    if (dartDefineKey.isNotEmpty) {
      return dartDefineKey.trim();
    }

    return _defaultApiKey;
  }

  /// Uploads an [XFile] (from ImagePicker) to ImgBB via Multipart POST request.
  /// Works across Android, iOS, Web, and Desktop by reading image bytes.
  /// Returns the permanent direct HTTPS URL of the hosted photo.
  static Future<String> uploadImage(XFile imageFile) async {
    final cleanKey = imgbbApiKey.trim();
    if (cleanKey.isEmpty) {
      throw const CloudImageException(
        'ImgBB API Key is missing!\n'
        'Please define IMGBB_API_KEY in your local .env file or via --dart-define=IMGBB_API_KEY=your_key.',
      );
    }

    try {
      final bytes = await imageFile.readAsBytes();
      if (bytes.isEmpty) {
        throw const CloudImageException('Selected image is empty.');
      }

      // Check file size (ImgBB free tier allows up to 32MB)
      if (bytes.lengthInBytes > 32 * 1024 * 1024) {
        throw const CloudImageException('Image size exceeds the 32MB limit. Please choose a smaller photo.');
      }

      final uri = Uri.parse('https://api.imgbb.com/1/upload');
      final request = http.MultipartRequest('POST', uri);

      request.fields['key'] = cleanKey;
      if (imageFile.name.isNotEmpty) {
        request.fields['name'] = imageFile.name;
      }

      final fileName = imageFile.name.isNotEmpty
          ? imageFile.name
          : 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: fileName,
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw const CloudImageException(
          'Image upload timed out. Please check your internet connection.',
        ),
      );

      final response = await http.Response.fromStream(streamedResponse);
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final imgData = data['data'] as Map<String, dynamic>?;
        final url = imgData?['display_url'] as String? ?? imgData?['url'] as String?;
        if (url != null && url.isNotEmpty) {
          return url;
        }
        throw const CloudImageException('ImgBB did not return a valid image URL.');
      } else {
        final errorMsg = data['error']?['message'] as String? ??
            data['status_txt'] as String? ??
            'HTTP ${response.statusCode}';
        throw CloudImageException('ImgBB error: $errorMsg');
      }
    } catch (e) {
      if (e is CloudImageException) rethrow;
      throw CloudImageException('Failed to upload image: ${e.toString()}');
    }
  }
}
