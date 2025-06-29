import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/order_model.dart';
import '../../models/order_detail_model.dart';
import '../../models/payment_model.dart';

class PaymentDashboardScreen extends StatefulWidget {
  const PaymentDashboardScreen({Key? key}) : super(key: key);

  @override
  State<PaymentDashboardScreen> createState() => _PaymentDashboardScreenState();
}

class _PaymentDashboardScreenState extends State<PaymentDashboardScreen> {
  List<Order> orders = [];
  OrderDetail? selectedOrderDetail;
  bool isLoading = true;
  bool isLoadingDetail = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/orders/get_orders.php'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<Order> loadedOrders = (data['data'] as List)
              .map((item) => Order.fromJson(item))
              .toList();
          setState(() {
            orders = loadedOrders;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Lỗi không xác định';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Lỗi kết nối API: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi khi load đơn hàng: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadOrderDetail(int orderId) async {
    setState(() {
      isLoadingDetail = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/orders/get_order_detail.php?order_id=$orderId'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final OrderDetail orderDetail = OrderDetail.fromJson(data['data']);
          setState(() {
            selectedOrderDetail = orderDetail;
            isLoadingDetail = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Lỗi không xác định';
            isLoadingDetail = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Lỗi kết nối API: ${response.statusCode}';
          isLoadingDetail = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi khi load chi tiết đơn hàng: $e';
        isLoadingDetail = false;
      });
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    if (selectedOrderDetail == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/orders/update_order.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_id': selectedOrderDetail!.id,
          'status': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Reload order detail
          await _loadOrderDetail(selectedOrderDetail!.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cập nhật trạng thái thành công')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${data['message']}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật: $e')),
      );
    }
  }

  Widget _buildOrderList() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Danh sách đơn hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final isSelected = selectedOrderDetail?.id == order.id;
                
                return ListTile(
                  selected: isSelected,
                  selectedTileColor: Colors.blue.withOpacity(0.1),
                  title: Text('Đơn hàng #${order.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Khách: ${order.userName ?? ''}'),
                      Text('Tổng: ${order.totalAmount.toStringAsFixed(0)} VNĐ'),
                      Text('Trạng thái: ${order.status}'),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  onTap: () => _loadOrderDetail(order.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'shipping':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOrderDetail() {
    if (selectedOrderDetail == null) {
      return const Card(
        child: Center(
          child: Text('Chọn một đơn hàng để xem chi tiết'),
        ),
      );
    }

    final order = selectedOrderDetail!;
    final showPaymentSection = order.status == 'confirmed' || 
                              order.status == 'shipping' || 
                              order.status == 'delivered';

    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chi tiết đơn hàng #${order.id}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    order.status,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Customer Information
            _buildSection('Thông tin khách hàng', [
              _buildInfoRow('Tên khách hàng', order.username ?? ''),
              _buildInfoRow('Email', order.email ?? ''),
              _buildInfoRow('Số điện thoại', order.phone ?? ''),
            ]),

            const SizedBox(height: 16),

            // Shipping Address
            _buildSection('Địa chỉ giao hàng', [
              _buildInfoRow('Địa chỉ', order.addressLine ?? ''),
              _buildInfoRow('Thành phố', order.city ?? ''),
              _buildInfoRow('Tỉnh', order.province ?? ''),
              if (order.postalCode != null)
                _buildInfoRow('Mã bưu điện', order.postalCode!),
            ]),

            const SizedBox(height: 16),

            // Order Information
            _buildSection('Thông tin đơn hàng', [
              _buildInfoRow('Ngày đặt hàng', order.orderDate),
              _buildInfoRow('Tổng tiền', '${order.totalAmount.toStringAsFixed(0)} VNĐ'),
            ]),

            const SizedBox(height: 16),

            // Order Status Update
            _buildSection('Cập nhật trạng thái', [
              DropdownButtonFormField<String>(
                value: order.status,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái đơn hàng',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Chờ xác nhận')),
                  DropdownMenuItem(value: 'confirmed', child: Text('Đã xác nhận')),
                  DropdownMenuItem(value: 'shipping', child: Text('Đang giao hàng')),
                  DropdownMenuItem(value: 'delivered', child: Text('Đã giao hàng')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _updateOrderStatus(value);
                  }
                },
              ),
            ]),

            const SizedBox(height: 16),

            // Order Items
            _buildSection('Sản phẩm trong đơn hàng', [
              ...order.items.map((item) => _buildOrderItem(item)),
            ]),

            const SizedBox(height: 16),

            // Payment Information (only show if order is confirmed or higher)
            if (showPaymentSection && order.payments.isNotEmpty)
              _buildPaymentSection(order.payments),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: item.imageUrl != null && item.imageUrl!.isNotEmpty
            ? Image.network(
                'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=${item.imageUrl}',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported),
              )
            : const Icon(Icons.image_not_supported),
        title: Text(item.productName ?? ''),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.variant != null && item.variant!.isNotEmpty)
              Text(item.variant!),
            Text('Số lượng: ${item.quantity} | Giá: ${item.price.toStringAsFixed(0)} VNĐ'),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection(List<Payment> payments) {
    return _buildSection('Lịch sử thanh toán', [
      ...payments.map((payment) => Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Phương thức: ${payment.paymentMethod}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPaymentStatusColor(payment.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      payment.status,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Số tiền', '${payment.amount.toStringAsFixed(0)} VNĐ'),
              if (payment.transactionCode != null)
                _buildInfoRow('Mã giao dịch', payment.transactionCode!),
              if (payment.paidAt != null)
                _buildInfoRow('Ngày thanh toán', payment.paidAt!),
            ],
          ),
        ),
      )),
    ]);
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "Dashboard Thanh toán",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadOrders,
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            if (isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (errorMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadOrders,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order List (1/3 width)
                    Expanded(
                      flex: 1,
                      child: _buildOrderList(),
                    ),
                    const SizedBox(width: 16),
                    // Order Detail (2/3 width)
                    Expanded(
                      flex: 2,
                      child: isLoadingDetail
                          ? const Center(child: CircularProgressIndicator())
                          : _buildOrderDetail(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
} 