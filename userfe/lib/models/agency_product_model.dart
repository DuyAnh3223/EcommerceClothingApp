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
  final String? approvalStatus;
  final String? reviewNotes;
  final String? reviewedAt;
  final String? reviewerName;
  final String createdAt;
  final String updatedAt;
  final List<AgencyProductVariant> variants;

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
    this.approvalStatus,
    this.reviewNotes,
    this.reviewedAt,
    this.reviewerName,
    required this.createdAt,
    required this.updatedAt,
    required this.variants,
  });

  factory AgencyProduct.fromJson(Map<String, dynamic> json) {
    return AgencyProduct(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      genderTarget: json['gender_target'],
      mainImage: json['main_image'],
      isAgencyProduct: json['is_agency_product'] == 1,
      status: json['status'],
      platformFeeRate: double.parse(json['platform_fee_rate'].toString()),
      approvalStatus: json['approval_status'],
      reviewNotes: json['review_notes'],
      reviewedAt: json['reviewed_at'],
      reviewerName: json['reviewer_name'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      variants: (json['variants'] as List)
          .map((v) => AgencyProductVariant.fromJson(v))
          .toList(),
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
      'is_agency_product': isAgencyProduct ? 1 : 0,
      'status': status,
      'platform_fee_rate': platformFeeRate,
      'approval_status': approvalStatus,
      'review_notes': reviewNotes,
      'reviewed_at': reviewedAt,
      'reviewer_name': reviewerName,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'variants': variants.map((v) => v.toJson()).toList(),
    };
  }
}

class AgencyProductVariant {
  final int variantId;
  final String sku;
  final double price;
  final int stock;
  final String? imageUrl;
  final String variantStatus;
  final Map<String, String> attributes;

  // Optionally store productId if needed for UI
  final int? productId;

  // For attribute value mapping (for UI compatibility)
  final List<AgencyVariantAttributeValue> attributeValues;

  AgencyProductVariant({
    required this.variantId,
    required this.sku,
    required this.price,
    required this.stock,
    this.imageUrl,
    required this.variantStatus,
    required this.attributes,
    this.productId,
    this.attributeValues = const [],
  });

  factory AgencyProductVariant.fromJson(Map<String, dynamic> json) {
    Map<String, String> attrs = {};
    if (json['attributes'] != null) {
      (json['attributes'] as Map<String, dynamic>).forEach((key, value) {
        attrs[key] = value.toString();
      });
    }
    // Parse attributeValues if present
    List<AgencyVariantAttributeValue> attrVals = [];
    if (json['attribute_values'] != null && json['attribute_values'] is List) {
      attrVals = (json['attribute_values'] as List)
          .map((v) => AgencyVariantAttributeValue.fromJson(v))
          .toList();
    }
    return AgencyProductVariant(
      variantId: json['variant_id'],
      sku: json['sku'],
      price: double.parse(json['price'].toString()),
      stock: json['stock'],
      imageUrl: json['image_url'],
      variantStatus: json['variant_status'] ?? json['status'] ?? 'active',
      attributes: attrs,
      productId: json['product_id'],
      attributeValues: attrVals,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variant_id': variantId,
      'sku': sku,
      'price': price,
      'stock': stock,
      'image_url': imageUrl,
      'variant_status': variantStatus,
      'attributes': attributes,
      'product_id': productId,
      'attribute_values': attributeValues.map((v) => v.toJson()).toList(),
    };
  }

  // --- Getters for UI compatibility ---
  int get id => variantId;
  String get attributesDisplay => attributes.entries.map((e) => "${e.key}: ${e.value}").join(", ");
  String get priceFormatted => "${price.toStringAsFixed(0)} đ";
  bool get isInStock => stock > 0;
  bool get isActive => variantStatus == 'active';
  String get status => variantStatus;
}

// Helper class for attribute value mapping (for UI compatibility)
class AgencyVariantAttributeValue {
  final int attributeId;
  final int valueId;
  AgencyVariantAttributeValue({required this.attributeId, required this.valueId});
  factory AgencyVariantAttributeValue.fromJson(Map<String, dynamic> json) {
    return AgencyVariantAttributeValue(
      attributeId: json['attribute_id'],
      valueId: json['value_id'],
    );
  }
  Map<String, dynamic> toJson() => {
    'attribute_id': attributeId,
    'value_id': valueId,
  };
}

class Attribute {
  final int id;
  final String name;
  final int? createdBy;
  final String? createdByName;
  final List<AttributeValue> values;

  Attribute({
    required this.id,
    required this.name,
    this.createdBy,
    this.createdByName,
    required this.values,
  });

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
      id: json['id'],
      name: json['name'],
      createdBy: json['created_by'],
      createdByName: json['created_by_name'],
      values: (json['values'] as List)
          .map((v) => AttributeValue.fromJson(v))
          .toList(),
    );
  }
}

class AttributeValue {
  final int id;
  final String value;
  final int? createdBy;
  final String? createdByName;

  AttributeValue({
    required this.id,
    required this.value,
    this.createdBy,
    this.createdByName,
  });

  factory AttributeValue.fromJson(Map<String, dynamic> json) {
    return AttributeValue(
      id: json['id'],
      value: json['value'],
      createdBy: json['created_by'],
      createdByName: json['created_by_name'],
    );
  }
} 