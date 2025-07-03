class CoinPackage {
  final int id;
  final String name;
  final double price;
  final double amount;
  final String description;

  CoinPackage({
    required this.id,
    required this.name,
    required this.price,
    required this.amount,
    required this.description,
  });

  factory CoinPackage.fromJson(Map<String, dynamic> json) {
    return CoinPackage(
      id: int.parse(json['id'].toString()),
      name: json['package_name'],
      price: double.parse(json['price_vnd'].toString()),
      amount: double.parse(json['bacoin_amount'].toString()),
      description: json['description'] ?? '',
    );
  }
}
class CoinTransaction {
  final int id;
  final double amount;
  final String type;
  final String? description;
  final String createdAt;

  CoinTransaction({
    required this.id,
    required this.amount,
    required this.type,
    this.description,
    required this.createdAt,
  });

  factory CoinTransaction.fromJson(Map<String, dynamic> json) {
    return CoinTransaction(
      id: int.parse(json['id'].toString()),
      amount: double.parse(json['amount'].toString()),
      type: json['type'] ?? '',
      description: json['description'],
      createdAt: json['created_at'] ?? '',
    );
  }
}