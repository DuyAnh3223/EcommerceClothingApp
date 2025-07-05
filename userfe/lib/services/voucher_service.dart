import 'dart:convert';
import 'package:http/http.dart' as http;

class VoucherService {
  static const String baseUrl = 'http://127.0.0.1/EcommerceClothingApp/API';

  // Validate voucher for specific products
  static Future<VoucherValidationResult> validateVoucher(String voucherCode, List<int> productIds) async {
    try {
      final requestBody = {
        'voucher_code': voucherCode,
        'product_ids': productIds,
      };
      
      final requestJson = json.encode(requestBody);
      
      print('=== DEBUG VOUCHER SERVICE ===');
      print('Request URL: $baseUrl/vouchers/validate_voucher.php');
      print('Request Method: POST');
      print('Request Headers: {"Content-Type": "application/json"}');
      print('Request Body (JSON): $requestJson');
      print('Request Body (Raw): ${requestBody.toString()}');
      print('Voucher Code: $voucherCode');
      print('Product IDs: $productIds');
      print('Product IDs Type: ${productIds.runtimeType}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/vouchers/validate_voucher.php'),
        headers: {'Content-Type': 'application/json'},
        body: requestJson,
      );

      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return VoucherValidationResult.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Voucher validation failed');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Voucher Service Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Get available vouchers for user
  static Future<List<Voucher>> getAvailableVouchers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vouchers/get_vouchers.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> vouchersData = data['data'] ?? [];
          return vouchersData.map((voucherData) => Voucher.fromJson(voucherData)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to get vouchers');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

class VoucherValidationResult {
  final int voucherId;
  final String voucherCode;
  final double discountAmount;
  final double totalDiscount;
  final List<int> applicableProducts;
  final int remainingQuantity;
  final String voucherType;
  final String? categoryFilter;

  VoucherValidationResult({
    required this.voucherId,
    required this.voucherCode,
    required this.discountAmount,
    required this.totalDiscount,
    required this.applicableProducts,
    required this.remainingQuantity,
    required this.voucherType,
    this.categoryFilter,
  });

  factory VoucherValidationResult.fromJson(Map<String, dynamic> json) {
    return VoucherValidationResult(
      voucherId: json['voucher_id'],
      voucherCode: json['voucher_code'],
      discountAmount: double.parse(json['discount_amount'].toString()),
      totalDiscount: double.parse(json['total_discount'].toString()),
      applicableProducts: List<int>.from(json['applicable_products']),
      remainingQuantity: json['remaining_quantity'],
      voucherType: json['voucher_type'],
      categoryFilter: json['category_filter'],
    );
  }

  String get formattedTotalDiscount {
    return '${totalDiscount.toStringAsFixed(0)} VNĐ';
  }

  String get formattedDiscountAmount {
    return '${discountAmount.toStringAsFixed(0)} VNĐ';
  }
}

class Voucher {
  final int id;
  final String voucherCode;
  final double discountAmount;
  final int quantity;
  final DateTime startDate;
  final DateTime endDate;
  final String voucherType;
  final String? categoryFilter;
  final List<int>? associatedProductIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Voucher({
    required this.id,
    required this.voucherCode,
    required this.discountAmount,
    required this.quantity,
    required this.startDate,
    required this.endDate,
    this.voucherType = 'all_products',
    this.categoryFilter,
    this.associatedProductIds,
    this.createdAt,
    this.updatedAt,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'],
      voucherCode: json['voucher_code'],
      discountAmount: double.parse(json['discount_amount'].toString()),
      quantity: json['quantity'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      voucherType: json['voucher_type'] ?? 'all_products',
      categoryFilter: json['category_filter'],
      associatedProductIds: json['associated_product_ids'] != null 
          ? List<int>.from(json['associated_product_ids'])
          : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  // Kiểm tra voucher có còn hiệu lực không
  bool get isValid {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  // Kiểm tra voucher có còn số lượng không
  bool get hasQuantity {
    return quantity > 0;
  }

  // Kiểm tra voucher có thể sử dụng không
  bool get canUse {
    return isValid && hasQuantity;
  }

  // Kiểm tra voucher có áp dụng cho tất cả sản phẩm không
  bool get isForAllProducts {
    return voucherType == 'all_products';
  }

  // Kiểm tra voucher có áp dụng cho sản phẩm cụ thể không
  bool get isForSpecificProducts {
    return voucherType == 'specific_products';
  }

  // Kiểm tra voucher có áp dụng theo danh mục không
  bool get isForCategoryBased {
    return voucherType == 'category_based';
  }

  // Kiểm tra voucher có áp dụng cho sản phẩm cụ thể không
  bool isApplicableForProduct(int productId) {
    if (isForAllProducts) return true;
    if (isForSpecificProducts && associatedProductIds != null) {
      return associatedProductIds!.contains(productId);
    }
    return false;
  }

  // Format ngày bắt đầu
  String get formattedStartDate {
    return '${startDate.day}/${startDate.month}/${startDate.year}';
  }

  // Format ngày kết thúc
  String get formattedEndDate {
    return '${endDate.day}/${endDate.month}/${endDate.year}';
  }

  // Format số tiền giảm giá
  String get formattedDiscountAmount {
    return '${discountAmount.toStringAsFixed(0)} VNĐ';
  }

  // Format loại voucher
  String get formattedVoucherType {
    switch (voucherType) {
      case 'all_products':
        return 'Tất cả sản phẩm';
      case 'specific_products':
        return 'Sản phẩm cụ thể';
      case 'category_based':
        return 'Theo danh mục';
      default:
        return 'Không xác định';
    }
  }
} 