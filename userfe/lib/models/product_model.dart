class Product {
  final int id;
  final String name;
  final String? description;
  final String category;
  final String genderTarget;
  final String? mainImage;
  final String createdAt;
  final String updatedAt;
  final List<ProductVariant> variants;
  final double? coinPrice;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.genderTarget,
    this.mainImage,
    required this.createdAt,
    required this.updatedAt,
    required this.variants,
    this.coinPrice,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      genderTarget: json['gender_target'],
      mainImage: json['main_image'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      variants: (json['variants'] as List)
          .map((variant) => ProductVariant.fromJson(variant))
          .toList(),
      coinPrice: json['coin_price'] != null ? double.parse(json['coin_price'].toString()) : null,
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
      'created_at': createdAt,
      'updated_at': updatedAt,
      'variants': variants.map((variant) => variant.toJson()).toList(),
    };
  }
}

class ProductVariant {
  final int variantId;
  final String sku;
  final double price;
  final int stock;
  final String status;
  final String? imageUrl;
  final List<AttributeValue> attributeValues;
  final double? priceBacoin;

  ProductVariant({
    required this.variantId,
    required this.sku,
    required this.price,
    required this.stock,
    required this.status,
    this.imageUrl,
    required this.attributeValues,
    this.priceBacoin,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json, [int? productId]) {
    return ProductVariant(
      variantId: json['variant_id'],
      sku: json['sku'],
      price: json['price'].toDouble(),
      stock: json['stock'],
      status: json['status'],
      imageUrl: json['image_url'],
      attributeValues: (json['attribute_values'] as List)
          .map((attr) => AttributeValue.fromJson(attr))
          .toList(),
      priceBacoin: json['price_bacoin'] != null ? double.tryParse(json['price_bacoin'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variant_id': variantId,
      'sku': sku,
      'price': price,
      'stock': stock,
      'status': status,
      'image_url': imageUrl,
      'attribute_values': attributeValues.map((attr) => attr.toJson()).toList(),
    };
  }
}

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
      attributeId: json['attribute_id'],
      attributeName: json['attribute_name'],
      valueId: json['value_id'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attribute_id': attributeId,
      'attribute_name': attributeName,
      'value_id': valueId,
      'value': value,
    };
  }
} 