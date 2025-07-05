import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bacoin_package_model.dart';
import '../constants.dart';

class BacoinPackageService {
  static const String baseUrl = API_BASE_URL;

  // Lấy danh sách tất cả gói BACoin
  static Future<List<BacoinPackage>> getPackages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/bacoin_packages/get_packages.php'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == 200 || responseData['status'] == 200) {
          final List<dynamic> packagesData = responseData['data'];
          return packagesData.map((json) => BacoinPackage.fromJson(json)).toList();
        } else {
          throw Exception(responseData['message'] ?? 'Failed to load packages');
        }
      } else {
        throw Exception('Failed to load packages');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Thêm gói BACoin mới
  static Future<BacoinPackage> addPackage(BacoinPackage package) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/bacoin_packages/add_package.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(package.toJson()),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData['success'] == 201 || responseData['status'] == 201) {
        return BacoinPackage.fromJson(responseData['data']);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to add package');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Cập nhật gói BACoin
  static Future<BacoinPackage> updatePackage(BacoinPackage package) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/bacoin_packages/update_package.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(package.toJson()),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData['success'] == 200 || responseData['status'] == 200) {
        return BacoinPackage.fromJson(responseData['data']);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to update package');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Xóa gói BACoin
  static Future<void> deletePackage(int packageId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/bacoin_packages/delete_package.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': packageId}),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData['success'] != 200 && responseData['status'] != 200) {
        throw Exception(responseData['message'] ?? 'Failed to delete package');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
} 