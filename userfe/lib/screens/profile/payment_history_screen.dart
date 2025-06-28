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

  String _getStatusDescription(String status) {
    switch (status) {
      case 'paid':
        return 'Giao dịch đã hoàn tất thành công';
      case 'pending':
        return 'Đang chờ xử lý thanh toán';
      case 'failed':
        return 'Giao dịch thất bại hoặc đã hủy';
      case 'canceled':
        return 'Giao dịch đã bị hủy';
      case 'refunded':
        return 'Tiền đã được hoàn lại';
      default:
        return 'Trạng thái không xác định';
    }
  }

  void _showPaymentDetail(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payment, color: _statusColor(payment['status'])),
            const SizedBox(width: 8),
            const Text('Chi tiết giao dịch'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Mã giao dịch', payment['transaction_code'] ?? '---'),
              _buildDetailRow('Số tiền', '${payment['amount']?.toStringAsFixed(0) ?? '---'} VNĐ'),
              _buildDetailRow('Phương thức', payment['payment_method'] ?? '---'),
              _buildDetailRow('Trạng thái', _statusText(payment['status']), 
                color: _statusColor(payment['status'])),
              _buildDetailRow('Mô tả', _getStatusDescription(payment['status'])),
              const Divider(),
              _buildDetailRow('Thời gian thanh toán', payment['paid_at'] ?? '---'),
              _buildDetailRow('Đơn hàng', '#${payment['order_id']}'),
              _buildDetailRow('Ngày đặt hàng', payment['order_date'] ?? '---'),
              _buildDetailRow('Tổng đơn hàng', '${payment['order_total']?.toStringAsFixed(0) ?? '---'} VNĐ'),
            ],
          ),
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

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color ?? Colors.black87,
              fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
            ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadPayments(refresh: true),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : payments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payment_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không có giao dịch nào',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Các giao dịch thanh toán sẽ xuất hiện ở đây',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadPayments(refresh: true),
                  child: ListView.separated(
                    itemCount: payments.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _statusColor(payment['status']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.payment,
                              color: _statusColor(payment['status']),
                              size: 24,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                'Đơn hàng #${payment['order_id']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Container(
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
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '💳 ${payment['payment_method'] ?? '---'}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                '💰 ${payment['amount']?.toStringAsFixed(0) ?? '---'} VNĐ',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange,
                                ),
                              ),
                              if (payment['transaction_code'] != null && payment['transaction_code'].isNotEmpty)
                                Text(
                                  '🔢 ${payment['transaction_code']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (payment['paid_at'] != null)
                                Text(
                                  '🕒 ${payment['paid_at']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                          onTap: () => _showPaymentDetail(payment),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
} 