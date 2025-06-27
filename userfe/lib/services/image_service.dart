import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ImageService {
  static const String baseUrl = 'http://127.0.0.1/EcommerceClothingApp/API';

  static Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      // Đọc bytes từ file
      final bytes = await imageFile.readAsBytes();
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/uploads/upload_image.php'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: 'image.jpg',
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);

      if (response.statusCode == 200 && jsonData['success']) {
        return {
          'success': true,
          'image_url': jsonData['url'],
          'filename': jsonData['filename'],
        };
      } else {
        return {
          'success': false,
          'message': jsonData['message'] ?? 'Upload thất bại',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  // Thêm method mới để upload từ bytes
  static Future<Map<String, dynamic>> uploadImageFromBytes(Uint8List bytes) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/uploads/upload_image.php'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: 'image.jpg',
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);

      if (response.statusCode == 200 && jsonData['success']) {
        return {
          'success': true,
          'image_url': jsonData['url'],
          'filename': jsonData['filename'],
        };
      } else {
        return {
          'success': false,
          'message': jsonData['message'] ?? 'Upload thất bại',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }
} 