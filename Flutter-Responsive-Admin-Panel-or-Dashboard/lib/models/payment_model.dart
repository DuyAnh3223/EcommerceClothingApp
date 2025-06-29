class Payment {
  final int id;
  final int orderId;
  final String paymentMethod;
  final double amount;
  final String status;
  final String? transactionCode;
  final String? paidAt;

  Payment({
    required this.id,
    required this.orderId,
    required this.paymentMethod,
    required this.amount,
    required this.status,
    this.transactionCode,
    this.paidAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      paymentMethod: json['payment_method'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0.0') ?? 0.0,
      status: json['status'] ?? '',
      transactionCode: json['transaction_code'],
      paidAt: json['paid_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'payment_method': paymentMethod,
    'amount': amount,
    'status': status,
    'transaction_code': transactionCode,
    'paid_at': paidAt,
  };
} 