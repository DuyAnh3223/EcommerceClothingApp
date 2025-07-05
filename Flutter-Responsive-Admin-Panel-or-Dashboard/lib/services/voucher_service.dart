import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/voucher_model.dart';
import '../constants.dart';

class VoucherService {
  static const String baseUrl = API_BASE_URL;

  // Lấy danh sách tất cả voucher
  static Future<List<Voucher>> getVouchers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/vouchers/get_vouchers.php'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == 200 || responseData['status'] == 200) {
          final List<dynamic> vouchersData = responseData['data'];
          return vouchersData.map((json) => Voucher.fromJson(json)).toList();
        } else {
          throw Exception(responseData['message'] ?? 'Failed to load vouchers');
        }
      } else {
        throw Exception('Failed to load vouchers');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Thêm voucher mới
  static Future<Voucher> addVoucher(Voucher voucher) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/vouchers/add_voucher.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(voucher.toJson()),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData['success'] == 201 || responseData['status'] == 201) {
        return Voucher.fromJson(responseData['data']);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to add voucher');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Cập nhật voucher
  static Future<Voucher> updateVoucher(Voucher voucher) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/vouchers/update_voucher.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(voucher.toJson()),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData['success'] == 200 || responseData['status'] == 200) {
        return Voucher.fromJson(responseData['data']);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to update voucher');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Xóa voucher
  static Future<void> deleteVoucher(int voucherId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/vouchers/delete_voucher.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': voucherId}),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData['success'] != 200 && responseData['status'] != 200) {
        throw Exception(responseData['message'] ?? 'Failed to delete voucher');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Validate voucher code
  static Future<Map<String, dynamic>> validateVoucher(String voucherCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vouchers/validate_voucher.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'voucher_code': voucherCode}),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);
      return responseData;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Lấy voucher theo mã
  static Future<Voucher?> getVoucherByCode(String voucherCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vouchers/get_voucher_by_code.php?voucher_code=$voucherCode'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == 200 || responseData['status'] == 200) {
          return Voucher.fromJson(responseData['data']);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
} 