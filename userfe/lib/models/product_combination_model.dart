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
  final String createdAt;
  final String updatedAt;
  final List<String> categories;
  final List<CombinationItem> items;

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
    required this.createdAt,
    required this.updatedAt,
    required this.categories,
    required this.items,
  });

  factory ProductCombination.fromJson(Map<String, dynamic> json) {
    return ProductCombination(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['image_url'],
      discountPrice: json['discount_price'] != null ? double.tryParse(json['discount_price'].toString()) : null,
      originalPrice: json['original_price'] != null ? double.tryParse(json['original_price'].toString()) : null,
      status: json['status'],
      createdBy: json['created_by'],
      creatorType: json['creator_type'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      categories: (json['categories'] as List).map((e) => e.toString()).toList(),
      items: (json['items'] as List).map((e) => CombinationItem.fromJson(e)).toList(),
    );
  }
}

class CombinationItem {
  final int id;
  final int productId;
  final int? variantId;
  final int quantity;
  final double? priceInCombination;
  final String? productName;
  final String? productImage;
  final String? productCategory;
  final String? sku;
  final double? originalPrice;
  final int? stock;
  final String? variantImage;

  CombinationItem({
    required this.id,
    required this.productId,
    this.variantId,
    required this.quantity,
    this.priceInCombination,
    this.productName,
    this.productImage,
    this.productCategory,
    this.sku,
    this.originalPrice,
    this.stock,
    this.variantImage,
  });

  factory CombinationItem.fromJson(Map<String, dynamic> json) {
    return CombinationItem(
      id: json['id'],
      productId: json['product_id'],
      variantId: json['variant_id'],
      quantity: json['quantity'],
      priceInCombination: json['price_in_combination'] != null ? double.tryParse(json['price_in_combination'].toString()) : null,
      productName: json['product_name'],
      productImage: json['product_image'],
      productCategory: json['product_category'],
      sku: json['sku'],
      originalPrice: json['original_price'] != null ? double.tryParse(json['original_price'].toString()) : null,
      stock: json['stock'],
      variantImage: json['variant_image'],
    );
  }
} 