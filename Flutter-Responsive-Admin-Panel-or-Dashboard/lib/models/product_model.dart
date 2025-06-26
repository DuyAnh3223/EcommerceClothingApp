class AttributeValue {
  final int attributeId;
  final String attributeName;
  final int valueId;
  final String value;

  AttributeValue({
    required this.attributeId,
    required this.attributeName,
    required this.valueId,
    required this.value,
  });

  factory AttributeValue.fromJson(Map<String, dynamic> json) {
    return AttributeValue(
      attributeId: json['attribute_id'] ?? 0,
      attributeName: json['attribute_name'] ?? '',
      valueId: json['value_id'] ?? 0,
      value: json['value'] ?? '',
    );
  }
}

class Product {
  final int id;
  final String name;
  final String description;
  final String category;
  final String genderTarget;
  final String createdAt;
  final String updatedAt;
  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.genderTarget,
    required this.createdAt,
    required this.updatedAt,
    required this.variants,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<ProductVariant> variantsList = [];
    if (json['variants'] != null) {
      variantsList = (json['variants'] as List)
          .map((variant) => ProductVariant.fromJson(variant, json['id']))
          .toList();
    }

    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      genderTarget: json['gender_target'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      variants: variantsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'gender_target': genderTarget,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'variants': variants.map((variant) => variant.toJson()).toList(),
    };
  }

  // Helper methods
  double get minPrice {
    if (variants.isEmpty) return 0.0;
    return variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
  }

  double get maxPrice {
    if (variants.isEmpty) return 0.0;
    return variants.map((v) => v.price).reduce((a, b) => a > b ? a : b);
  }

  int get totalStock {
    return variants.fold(0, (sum, variant) => sum + variant.stock);
  }

  bool get hasActiveVariants {
    return variants.any((v) => v.status == 'active');
  }
}

class ProductVariant {
  final int id;
  final int productId;
  final String sku;
  final double price;
  final int stock;
  final String imageUrl;
  final String status;
  final List<AttributeValue> attributeValues;

  ProductVariant({
    required this.id,
    required this.productId,
    required this.sku,
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.status,
    required this.attributeValues,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json, int productId) {
    List<AttributeValue> attrs = [];
    if (json['attribute_values'] != null) {
      attrs = (json['attribute_values'] as List)
          .map((e) => AttributeValue.fromJson(e))
          .toList();
    }
    return ProductVariant(
      id: json['variant_id'] ?? json['id'] ?? 0,
      productId: productId,
      sku: json['sku'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      stock: json['stock'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      status: json['status'] ?? '',
      attributeValues: attrs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'sku': sku,
      'price': price,
      'stock': stock,
      'image_url': imageUrl,
      'status': status,
      'attribute_values': attributeValues.map((e) => {
        'attribute_id': e.attributeId,
        'attribute_name': e.attributeName,
        'value_id': e.valueId,
        'value': e.value,
      }).toList(),
    };
  }

  bool get isInStock => stock > 0;
  bool get isActive => status == 'active';
  String get priceFormatted => '${price.toStringAsFixed(0)} VNĐ';
  String get attributesDisplay => attributeValues.map((e) => '${e.attributeName}: ${e.value}').join(', ');
}
