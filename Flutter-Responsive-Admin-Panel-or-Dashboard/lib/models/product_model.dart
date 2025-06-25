// class Product {
//   final String id;
//   final String name;
//   final String description;
//   final double price;
//   final int stock;
//   final String status;
//   final String color;
//   final String size;
//   final String image;

//   Product({
//     required this.id,
//     required this.name,
//     required this.description,
//     required this.price,
//     required this.stock,
//     required this.status,
//     required this.color,
//     required this.size,
//     required this.image,
//   });

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//       'description': description,
//       'price': price,
//       'stock': stock,
//       'status': status,
//       'color': color,
//       'size': size,
//       'image': image,
//     };
//   }
// }

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
          .map((variant) => ProductVariant.fromJson(variant))
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

  List<String> get availableColors {
    return variants.map((v) => v.color).toSet().toList();
  }

  List<String> get availableSizes {
    return variants.map((v) => v.size).toSet().toList();
  }

  bool get hasActiveVariants {
    return variants.any((v) => v.status == 'active');
  }
}

class ProductVariant {
  final int id;
  final int productId;
  final String color;
  final String size;
  final String material;
  final double price;
  final int stock;
  final String imageUrl;
  final String status;

  ProductVariant({
    required this.id,
    required this.productId,
    required this.color,
    required this.size,
    required this.material,
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.status,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      color: json['color'] ?? '',
      size: json['size'] ?? '',
      material: json['material'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      stock: json['stock'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'color': color,
      'size': size,
      'material': material,
      'price': price,
      'stock': stock,
      'image_url': imageUrl,
      'status': status,
    };
  }

  // Helper methods
  bool get isInStock => stock > 0;
  bool get isActive => status == 'active';
  String get displayName => '$color - $size';
  String get priceFormatted => '${price.toStringAsFixed(0)} VNĐ';
}
