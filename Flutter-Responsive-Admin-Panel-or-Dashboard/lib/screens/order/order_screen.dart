// lib/screens/order/order_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/order_model.dart';
import 'order_detail_screen.dart';
import 'add_edit_order_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<Order> orders = [];
  bool isLoading = true;
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

  void _viewOrderDetail(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(order: order),
      ),
    );
  }

  void _addOrder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditOrderScreen()),
    );
    if (result != null) {
      _loadOrders();
    }
  }

  void _editOrder(Order order) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditOrderScreen(order: order)),
    );
    if (result != null) {
      _loadOrders();
    }
  }

  void _deleteOrder(Order order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Bạn có chắc chắn muốn xóa đơn hàng #${order.id}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/orders/delete_order.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'id': order.id}),
        );
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _loadOrders();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${data['message']}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa: $e')),
        );
      }
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
                  "Quản lý đơn hàng",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadOrders,
                ),
                // ElevatedButton.icon(
                //   icon: const Icon(Icons.add),
                //   label: const Text('Thêm đơn hàng'),
                //   onPressed: _addOrder,
                // ),
              ],
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage != null)
              Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
            else
              Expanded(
                child: Builder(
                  builder: (context) {
                    final pendingOrders = orders.where((order) => order.status == "pending").toList();
                    return ListView.builder(
                      itemCount: pendingOrders.length,
                      itemBuilder: (context, index) {
                        final order = pendingOrders[index];
                        return Card(
                          child: ListTile(
                            title: Text('Đơn hàng #${order.id} - ${order.status}'),
                            subtitle: Text('Khách: ${order.userName ?? ''} - Tổng: ${order.totalAmount} VNĐ'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  tooltip: 'Sửa',
                                  onPressed: () => _editOrder(order),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Xóa',
                                  onPressed: () => _deleteOrder(order),
                                ),
                                const Icon(Icons.arrow_forward_ios),
                              ],
                            ),
                            onTap: () => _viewOrderDetail(order),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}