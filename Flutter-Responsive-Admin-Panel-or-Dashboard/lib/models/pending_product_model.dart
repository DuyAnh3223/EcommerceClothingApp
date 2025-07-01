class PendingProduct {
  final int id;
  final String name;
  final String description;
  final String category;
  final String genderTarget;
  final String? mainImage;
  final String status;
  final String agencyName;
  final String agencyEmail;
  final String agencyPhone;
  final String createdAt;
  final String updatedAt;
  final List<ProductVariant> variants;
  final String? reviewNotes;
  final String? reviewedAt;
  final String? reviewerName;

  PendingProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.genderTarget,
    this.mainImage,
    required this.status,
    required this.agencyName,
    required this.agencyEmail,
    required this.agencyPhone,
    required this.createdAt,
    required this.updatedAt,
    required this.variants,
    this.reviewNotes,
    this.reviewedAt,
    this.reviewerName,
  });

  factory PendingProduct.fromJson(Map<String, dynamic> json) {
    return PendingProduct(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      genderTarget: json['gender_target'],
      mainImage: json['main_image'],
      status: json['status'],
      agencyName: json['agency_name'] ?? '',
      agencyEmail: json['agency_email'] ?? '',
      agencyPhone: json['agency_phone'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      variants: (json['variants'] as List?)
          ?.map((v) => ProductVariant.fromJson(v))
          .toList() ?? [],
      reviewNotes: json['review_notes'],
      reviewedAt: json['reviewed_at'],
      reviewerName: json['reviewer_name'],
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
      'status': status,
      'agency_name': agencyName,
      'agency_email': agencyEmail,
      'agency_phone': agencyPhone,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'variants': variants.map((v) => v.toJson()).toList(),
      'review_notes': reviewNotes,
      'reviewed_at': reviewedAt,
      'reviewer_name': reviewerName,
    };
  }
}

class ProductVariant {
  final int variantId;
  final String sku;
  final double price;
  final int stock;
  final String? imageUrl;
  final String variantStatus;

  ProductVariant({
    required this.variantId,
    required this.sku,
    required this.price,
    required this.stock,
    this.imageUrl,
    required this.variantStatus,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      variantId: json['variant_id'],
      sku: json['sku'],
      price: double.parse(json['price'].toString()),
      stock: json['stock'],
      imageUrl: json['image_url'],
      variantStatus: json['variant_status'],
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
    };
  }
} 