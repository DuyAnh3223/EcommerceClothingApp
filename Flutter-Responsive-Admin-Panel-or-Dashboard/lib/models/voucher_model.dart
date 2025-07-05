class Voucher {
  final int id;
  final String voucherCode;
  final double discountAmount;
  final int quantity;
  final DateTime startDate;
  final DateTime endDate;
  final String voucherType; // 'all_products', 'specific_products', 'category_based'
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'voucher_code': voucherCode,
      'discount_amount': discountAmount,
      'quantity': quantity,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'voucher_type': voucherType,
      'category_filter': categoryFilter,
      'associated_product_ids': associatedProductIds,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Voucher copyWith({
    int? id,
    String? voucherCode,
    double? discountAmount,
    int? quantity,
    DateTime? startDate,
    DateTime? endDate,
    String? voucherType,
    String? categoryFilter,
    List<int>? associatedProductIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Voucher(
      id: id ?? this.id,
      voucherCode: voucherCode ?? this.voucherCode,
      discountAmount: discountAmount ?? this.discountAmount,
      quantity: quantity ?? this.quantity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      voucherType: voucherType ?? this.voucherType,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      associatedProductIds: associatedProductIds ?? this.associatedProductIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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

  @override
  String toString() {
    return 'Voucher(id: $id, voucherCode: $voucherCode, discountAmount: $discountAmount, quantity: $quantity, startDate: $startDate, endDate: $endDate, voucherType: $voucherType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Voucher &&
        other.id == id &&
        other.voucherCode == voucherCode &&
        other.discountAmount == discountAmount &&
        other.quantity == quantity &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.voucherType == voucherType;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        voucherCode.hashCode ^
        discountAmount.hashCode ^
        quantity.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        voucherType.hashCode;
  }
} 