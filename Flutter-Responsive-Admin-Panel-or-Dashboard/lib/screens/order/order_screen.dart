// lib/screens/order/order_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/order_model.dart';
import 'order_detail_screen.dart';

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
        Uri.parse('http://localhost/EcommerceClothingApp/API/orders/get_orders.php'),
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
              ],
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage != null)
              Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      child: ListTile(
                        title: Text('Đơn hàng #${order.id} - ${order.status}'),
                        subtitle: Text('Khách: ${order.userName ?? ''} - Tổng: ${order.totalAmount} VNĐ'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _viewOrderDetail(order),
                      ),
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