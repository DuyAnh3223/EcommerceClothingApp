class Order {
  final int id;
  final int userId;
  final String? userName;
  final int addressId;
  final String orderDate;
  final double totalAmount;
  final String status;

  Order({
    required this.id,
    required this.userId,
    this.userName,
    required this.addressId,
    required this.orderDate,
    required this.totalAmount,
    required this.status,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? json['username'],
      addressId: json['address_id'] ?? 0,
      orderDate: json['order_date'] ?? '',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0.0') ?? 0.0,
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'user_name': userName,
    'address_id': addressId,
    'order_date': orderDate,
    'total_amount': totalAmount,
    'status': status,
  };
}
