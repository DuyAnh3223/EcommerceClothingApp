import 'package:flutter/material.dart';
import '../../services/payment_service.dart';
import '../../services/auth_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<Map<String, dynamic>> payments = [];
  bool isLoading = true;
  int currentPage = 1;
  int totalPages = 1;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await AuthService.getUserData();
    if (data != null) {
      setState(() {
        userData = data;
      });
      await _loadPayments(refresh: true);
    }
  }

  Future<void> _loadPayments({bool refresh = false}) async {
    if (userData == null) return;
    if (refresh) {
      setState(() {
        isLoading = true;
        currentPage = 1;
      });
    }
    final result = await PaymentService.getPayments(userId: userData!['id'], page: currentPage);
    if (mounted) {
      setState(() {
        isLoading = false;
      });
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        payments = List<Map<String, dynamic>>.from(data['payments'] ?? []);
        totalPages = data['pagination']?['total_pages'] ?? 1;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Lỗi tải dữ liệu'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'canceled':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'paid':
        return 'Đã thanh toán';
      case 'pending':
        return 'Chờ thanh toán';
      case 'failed':
        return 'Thất bại';
      case 'canceled':
        return 'Đã hủy';
      case 'refunded':
        return 'Đã hoàn tiền';
      default:
        return status;
    }
  }

  void _showPaymentDetail(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chi tiết giao dịch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mã giao dịch: ${payment['transaction_code'] ?? '---'}'),
            Text('Số tiền: ${payment['amount']?.toStringAsFixed(0) ?? '---'} VNĐ'),
            Text('Phương thức: ${payment['payment_method'] ?? '---'}'),
            Text('Trạng thái: ${_statusText(payment['status'])}'),
            Text('Thời gian thanh toán: ${payment['paid_at'] ?? '---'}'),
            Text('Đơn hàng: #${payment['order_id']}'),
            Text('Ngày đặt hàng: ${payment['order_date'] ?? '---'}'),
            Text('Tổng đơn hàng: ${payment['order_total']?.toStringAsFixed(0) ?? '---'} VNĐ'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử thanh toán'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : payments.isEmpty
              ? const Center(child: Text('Không có giao dịch nào'))
              : RefreshIndicator(
                  onRefresh: () => _loadPayments(refresh: true),
                  child: ListView.separated(
                    itemCount: payments.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return ListTile(
                        leading: Icon(Icons.payment, color: _statusColor(payment['status'])),
                        title: Text('Đơn hàng #${payment['order_id']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Số tiền: ${payment['amount']?.toStringAsFixed(0) ?? '---'} VNĐ'),
                            Text('Phương thức: ${payment['payment_method'] ?? '---'}'),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(payment['status']).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _statusText(payment['status']),
                            style: TextStyle(
                              color: _statusColor(payment['status']),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        onTap: () => _showPaymentDetail(payment),
                      );
                    },
                  ),
                ),
    );
  }
} 