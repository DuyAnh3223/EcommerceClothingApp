import 'payment_model.dart';

class OrderDetail {
  final int id;
  final int userId;
  final String? username;
  final String? email;
  final String? phone;
  final int addressId;
  final String? addressLine;
  final String? city;
  final String? province;
  final String? postalCode;
  final String orderDate;
  final double totalAmount;
  final String status;
  final String createdAt;
  final String updatedAt;
  final List<OrderItem> items;
  final List<Payment> payments;

  OrderDetail({
    required this.id,
    required this.userId,
    this.username,
    this.email,
    this.phone,
    required this.addressId,
    this.addressLine,
    this.city,
    this.province,
    this.postalCode,
    required this.orderDate,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.payments,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      username: json['username'],
      email: json['email'],
      phone: json['phone'],
      addressId: json['address_id'] ?? 0,
      addressLine: json['address_line'],
      city: json['city'],
      province: json['province'],
      postalCode: json['postal_code'],
      orderDate: json['order_date'] ?? '',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0.0') ?? 0.0,
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      payments: (json['payments'] as List? ?? [])
          .map((payment) => Payment.fromJson(payment))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'username': username,
    'email': email,
    'phone': phone,
    'address_id': addressId,
    'address_line': addressLine,
    'city': city,
    'province': province,
    'postal_code': postalCode,
    'order_date': orderDate,
    'total_amount': totalAmount,
    'status': status,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'items': items.map((item) => item.toJson()).toList(),
    'payments': payments.map((payment) => payment.toJson()).toList(),
  };
}

class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final int variantId;
  final int quantity;
  final double price;
  final String? productName;
  final String? variant;
  final String? imageUrl;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.variantId,
    required this.quantity,
    required this.price,
    this.productName,
    this.variant,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      variantId: json['variant_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      productName: json['product_name'],
      variant: json['variant'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'product_id': productId,
    'variant_id': variantId,
    'quantity': quantity,
    'price': price,
    'product_name': productName,
    'variant': variant,
    'image_url': imageUrl,
  };
} 