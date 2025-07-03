class CoinPackage {
  final int id;
  final String name;
  final int price;
  final int coinAmount;
  final String? description;

  CoinPackage({
    required this.id,
    required this.name,
    required this.price,
    required this.coinAmount,
    this.description,
  });

  factory CoinPackage.fromJson(Map<String, dynamic> json) {
    return CoinPackage(
      id: int.parse(json['id'].toString()),
      name: json['package_name'],
      price: int.parse(json['price_vnd'].toString()),
      coinAmount: int.parse(json['bacoin_amount'].toString()),
      description: json['description'],
    );
  }
}
class CoinTransaction {
  final int id;
  final int amount;
  final String type;
  final String? description;
  final DateTime createdAt;

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
      amount: int.parse(json['amount'].toString()),
      type: json['type'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}