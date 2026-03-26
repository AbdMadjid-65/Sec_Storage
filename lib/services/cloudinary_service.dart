import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  static const String _cloudName = 'dqed2mebk';
  static const String _uploadPreset = 'privault_uploads';
  static const String _apiUrl = 'https://api.cloudinary.com/v1_1/$_cloudName/auto/upload';

  /// Uploads a generic file to Cloudinary
  static Future<String> uploadFile(Uint8List bytes, String publicId) async {
    return _upload(bytes, publicId);
  }

  /// Uploads a user profile photo to Cloudinary.
  /// Uses a unique public_id per upload (timestamped) so the returned URL
  /// is always different — this eliminates all CDN / HTTP / Flutter image
  /// caching issues.
  static Future<String> uploadProfilePhoto(Uint8List bytes, String userId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final publicId = 'users/$userId/avatar_$timestamp';
    return _upload(bytes, publicId);
  }

  static Future<String> _upload(Uint8List bytes, String publicId) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));

      request.fields['upload_preset'] = _uploadPreset;
      request.fields['public_id'] = publicId;

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: publicId.split('/').last,
        contentType: MediaType('application', 'octet-stream'), 
      );

      request.files.add(multipartFile);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(responseBody);
        return jsonResponse['secure_url'] as String;
      } else {
        throw Exception('Cloudinary upload failed: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      throw Exception('Failed to upload file to Cloudinary: $e');
    }
  }

  /// Cloudinary does not natively allow unsigned DELETES for security reasons.
  /// However, keeping the signature identical for the repository.
  static Future<void> deleteFile(String publicId) async {
     // NOTE: Standard unsigned uploads cannot be deleted strictly from the client using just the preset.
     // Normally this requires the API Secret to sign an authenticated destroy request.
     // For this iteration, we log it or use an authenticated backend endpoint if necessary.
     // ignore: avoid_print
     print('Cloudinary Delete requested for: $publicId (Requires signed backend request or API Secret in real deployment)');
  }
}
