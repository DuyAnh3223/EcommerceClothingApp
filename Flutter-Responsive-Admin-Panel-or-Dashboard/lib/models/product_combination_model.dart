class ProductCombination {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final double? discountPrice;
  final double? originalPrice;
  final String status;
  final int createdBy;
  final String creatorType;
  final String creatorName;
  final String creatorEmail;
  final List<String> categories;
  final List<ProductCombinationItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductCombination({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.discountPrice,
    this.originalPrice,
    required this.status,
    required this.createdBy,
    required this.creatorType,
    required this.creatorName,
    required this.creatorEmail,
    required this.categories,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductCombination.fromJson(Map<String, dynamic> json) {
    return ProductCombination(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['image_url'],
      discountPrice: json['discount_price'] != null
          ? double.tryParse(json['discount_price'].toString())
          : null,
      originalPrice: json['original_price'] != null
          ? double.tryParse(json['original_price'].toString())
          : null,
      status: json['status'] ?? '',
      createdBy: json['created_by'] is int
          ? json['created_by']
          : int.tryParse(json['created_by']?.toString() ?? '') ?? 0,
      creatorType: json['creator_type'] ?? '',
      creatorName: json['creator_name'] ?? '',
      creatorEmail: json['creator_email'] ?? '',
      categories: List<String>.from(json['categories'] ?? []),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => ProductCombinationItem.fromJson(item))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'discount_price': discountPrice,
      'original_price': originalPrice,
      'status': status,
      'created_by': createdBy,
      'creator_type': creatorType,
      'creator_name': creatorName,
      'creator_email': creatorEmail,
      'categories': categories,
      'items': items.map((item) => item.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  String get statusDisplay {
    switch (status) {
      case 'active':
        return 'Hoạt động';
      case 'inactive':
        return 'Không hoạt động';
      case 'pending':
        return 'Chờ duyệt';
      default:
        return status;
    }
  }

  String get creatorTypeDisplay {
    switch (creatorType) {
      case 'admin':
        return 'Admin';
      case 'agency':
        return 'Agency';
      default:
        return creatorType;
    }
  }

  double get savings {
    if (originalPrice != null && discountPrice != null) {
      return originalPrice! - discountPrice!;
    }
    return 0.0;
  }

  double get savingsPercentage {
    if (originalPrice != null && discountPrice != null && originalPrice! > 0) {
      return ((originalPrice! - discountPrice!) / originalPrice!) * 100;
    }
    return 0.0;
  }

  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  bool get hasDiscount {
    return discountPrice != null && originalPrice != null && discountPrice! < originalPrice!;
  }
}

class ProductCombinationItem {
  final int id;
  final int combinationId;
  final int productId;
  final int? variantId;
  final int quantity;
  final double? priceInCombination;
  final String productName;
  final String? productImage;
  final String productCategory;
  final String? sku;
  final double? originalPrice;
  final int stock;
  final String? variantImage;
  final String? genderTarget;
  final String? color;
  final String? size;
  final String? brand;

  ProductCombinationItem({
    required this.id,
    required this.combinationId,
    required this.productId,
    this.variantId,
    required this.quantity,
    this.priceInCombination,
    required this.productName,
    this.productImage,
    required this.productCategory,
    this.sku,
    this.originalPrice,
    required this.stock,
    this.variantImage,
    this.genderTarget,
    this.color,
    this.size,
    this.brand,
  });

  factory ProductCombinationItem.fromJson(Map<String, dynamic> json) {
    return ProductCombinationItem(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      combinationId: json['combination_id'] is int
          ? json['combination_id']
          : int.tryParse(json['combination_id']?.toString() ?? '') ?? 0,
      productId: json['product_id'] is int
          ? json['product_id']
          : int.tryParse(json['product_id']?.toString() ?? '') ?? 0,
      variantId: json['variant_id'] == null
          ? null
          : (json['variant_id'] is int
              ? json['variant_id']
              : int.tryParse(json['variant_id'].toString())),
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      priceInCombination: json['price_in_combination'] != null
          ? double.tryParse(json['price_in_combination'].toString())
          : null,
      productName: json['product_name'] ?? '',
      productImage: json['product_image'],
      productCategory: json['product_category'] ?? '',
      sku: json['sku'],
      originalPrice: json['original_price'] != null
          ? double.tryParse(json['original_price'].toString())
          : null,
      stock: json['stock'] is int
          ? json['stock']
          : int.tryParse(json['stock']?.toString() ?? '') ?? 0,
      variantImage: json['variant_image'],
      genderTarget: json['gender_target']?.toString(),
      color: json['color']?.toString(),
      size: json['size']?.toString(),
      brand: json['brand']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'combination_id': combinationId,
      'product_id': productId,
      'variant_id': variantId,
      'quantity': quantity,
      'price_in_combination': priceInCombination,
      'product_name': productName,
      'product_image': productImage,
      'product_category': productCategory,
      'sku': sku,
      'original_price': originalPrice,
      'stock': stock,
      'variant_image': variantImage,
      'gender_target': genderTarget,
      'color': color,
      'size': size,
      'brand': brand,
    };
  }

  // Helper methods
  double get effectivePrice {
    return priceInCombination ?? originalPrice ?? 0.0;
  }

  String get displayImage {
    return variantImage ?? productImage ?? '';
  }

  bool get hasVariant {
    return variantId != null;
  }
} 