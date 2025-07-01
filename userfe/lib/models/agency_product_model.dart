class AgencyProduct {
  final int id;
  final String name;
  final String description;
  final String category;
  final String genderTarget;
  final String? mainImage;
  final bool isAgencyProduct;
  final String status;
  final double platformFeeRate;
  final String createdAt;
  final String updatedAt;
  final String? approvalStatus;
  final String? reviewNotes;
  final String? reviewedAt;
  final String? reviewerName;
  final List<ProductVariant> variants;

  AgencyProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.genderTarget,
    this.mainImage,
    required this.isAgencyProduct,
    required this.status,
    required this.platformFeeRate,
    required this.createdAt,
    required this.updatedAt,
    this.approvalStatus,
    this.reviewNotes,
    this.reviewedAt,
    this.reviewerName,
    required this.variants,
  });

  factory AgencyProduct.fromJson(Map<String, dynamic> json) {
    return AgencyProduct(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'],
      description: json['description'] ?? '',
      category: json['category'],
      genderTarget: json['gender_target'],
      mainImage: json['main_image'],
      isAgencyProduct: json['is_agency_product'] == 1,
      status: json['status'],
      platformFeeRate: double.tryParse(json['platform_fee_rate'].toString()) ?? 0.0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      approvalStatus: json['approval_status'],
      reviewNotes: json['review_notes'],
      reviewedAt: json['reviewed_at'],
      reviewerName: json['reviewer_name'],
      variants: (json['variants'] as List<dynamic>?)
              ?.map((variant) => ProductVariant.fromJson(variant))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'gender_target': genderTarget,
      'main_image': mainImage,
      'is_agency_product': isAgencyProduct,
      'status': status,
      'platform_fee_rate': platformFeeRate,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'approval_status': approvalStatus,
      'review_notes': reviewNotes,
      'reviewed_at': reviewedAt,
      'reviewer_name': reviewerName,
      'variants': variants.map((variant) => variant.toJson()).toList(),
    };
  }

  // Helper methods
  bool get isInactive => status == 'inactive';
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get canEdit => isInactive || isRejected;
  bool get canSubmit => isInactive || isRejected;
  bool get canDelete => isInactive || isRejected;

  String get statusDisplay {
    switch (status) {
      case 'inactive':
        return 'Không hoạt động';
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Từ chối';
      default:
        return status;
    }
  }

  String get approvalStatusDisplay {
    switch (approvalStatus) {
      case 'inactive':
        return 'Không hoạt động';
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Từ chối';
      default:
        return approvalStatus ?? 'Không xác định';
    }
  }
}

class ProductVariant {
  final int id;
  final String sku;
  final double price;
  final int stock;
  final String? imageUrl;
  final String status;
  final List<AttributeValue> attributes;
  final int? productId;

  ProductVariant({
    required this.id,
    required this.sku,
    required this.price,
    required this.stock,
    this.imageUrl,
    required this.status,
    required this.attributes,
    this.productId,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    try {
      // Handle both 'id' and 'variant_id' fields
      final id = int.tryParse((json['variant_id'] ?? json['id']).toString()) ?? 0;
      final sku = json['sku'] ?? '';
      final price = double.tryParse(json['price'].toString()) ?? 0.0;
      final stock = int.tryParse(json['stock'].toString()) ?? 0;
      final imageUrl = json['image_url'];
      // Handle both 'status' and 'variant_status' fields
      final status = json['variant_status'] ?? json['status'] ?? 'active';
      final productId = int.tryParse(json['product_id'].toString());
      
      final attributes = (json['attributes'] as List<dynamic>?)
          ?.map((attr) => AttributeValue.fromJson(attr))
          .toList() ?? [];
      
      return ProductVariant(
        id: id,
        sku: sku,
        price: price,
        stock: stock,
        imageUrl: imageUrl,
        status: status,
        attributes: attributes,
        productId: productId,
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'price': price,
      'stock': stock,
      'image_url': imageUrl,
      'status': status,
      'attributes': attributes.map((attr) => attr.toJson()).toList(),
      'product_id': productId,
    };
  }

  String get priceFormatted => '${price.toStringAsFixed(0)} VNĐ';
  bool get isInStock => stock > 0;
  bool get isActive => status == 'active';
  String get attributesDisplay => attributes.map((attr) => '${attr.attributeName}: ${attr.value}').join(', ');
}

class Attribute {
  final int id;
  final String name;
  final String createdAt;
  final String? createdByName;
  final List<AttributeValue> values;

  Attribute({
    required this.id,
    required this.name,
    required this.createdAt,
    this.createdByName,
    required this.values,
  });

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'],
      createdAt: json['created_at'],
      createdByName: json['created_by_name'],
      values: (json['values'] as List<dynamic>?)
              ?.map((value) => AttributeValue.fromJson(value))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
      'created_by_name': createdByName,
      'values': values.map((value) => value.toJson()).toList(),
    };
  }
}

class AttributeValue {
  final int id;
  final String value;
  final int attributeId;
  final String attributeName;
  final int? createdBy;
  final String? createdByName;

  AttributeValue({
    required this.id,
    required this.value,
    required this.attributeId,
    required this.attributeName,
    this.createdBy,
    this.createdByName,
  });

  factory AttributeValue.fromJson(Map<String, dynamic> json) {
    try {
      print('DEBUG: AttributeValue.fromJson input: $json');
      
      // Handle both 'id' and 'value_id' fields
      final id = int.tryParse((json['value_id'] ?? json['id']).toString()) ?? 0;
      final value = json['value'];
      final attributeId = int.tryParse(json['attribute_id'].toString()) ?? 0;
      final attributeName = json['attribute_name'] ?? '';
      final createdBy = int.tryParse(json['created_by'].toString());
      final createdByName = json['created_by_name'];
      
      print('DEBUG: AttributeValue parsed - id: $id, value: $value, attributeId: $attributeId');
      
      return AttributeValue(
        id: id,
        value: value,
        attributeId: attributeId,
        attributeName: attributeName,
        createdBy: createdBy,
        createdByName: createdByName,
      );
    } catch (e) {
      print('DEBUG: Error in AttributeValue.fromJson: $e');
      print('DEBUG: JSON that caused error: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
      'attribute_id': attributeId,
      'attribute_name': attributeName,
      'created_by': createdBy,
      'created_by_name': createdByName,
    };
  }
} 