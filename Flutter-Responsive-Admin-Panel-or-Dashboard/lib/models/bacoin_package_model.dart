class BacoinPackage {
  final int id;
  final String packageName;
  final double priceVnd;
  final double bacoinAmount;
  final String? description;

  BacoinPackage({
    required this.id,
    required this.packageName,
    required this.priceVnd,
    required this.bacoinAmount,
    this.description,
  });

  factory BacoinPackage.fromJson(Map<String, dynamic> json) {
    return BacoinPackage(
      id: json['id'],
      packageName: json['package_name'],
      priceVnd: double.parse(json['price_vnd'].toString()),
      bacoinAmount: double.parse(json['bacoin_amount'].toString()),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'package_name': packageName,
      'price_vnd': priceVnd,
      'bacoin_amount': bacoinAmount,
      'description': description,
    };
  }

  BacoinPackage copyWith({
    int? id,
    String? packageName,
    double? priceVnd,
    double? bacoinAmount,
    String? description,
  }) {
    return BacoinPackage(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      priceVnd: priceVnd ?? this.priceVnd,
      bacoinAmount: bacoinAmount ?? this.bacoinAmount,
      description: description ?? this.description,
    );
  }
} 