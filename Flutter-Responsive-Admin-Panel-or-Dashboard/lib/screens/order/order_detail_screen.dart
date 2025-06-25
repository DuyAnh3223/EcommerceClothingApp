// lib/screens/order/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/order_model.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;
  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  List<dynamic> orderItems = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrderItems();
  }

  Future<void> _loadOrderItems() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost/EcommerceClothingApp/API/orders/get_order_items.php?order_id=${widget.order.id}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            orderItems = data['items'];
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
        errorMessage = 'Lỗi khi load chi tiết đơn hàng: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn hàng #${order.id}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Khách hàng: ${order.userName ?? ''}'),
            Text('Tổng tiền: ${order.totalAmount} VNĐ'),
            Text('Trạng thái: ${order.status}'),
            const Divider(),
            const Text('Chi tiết sản phẩm:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage != null)
              Text(errorMessage!, style: const TextStyle(color: Colors.red))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: orderItems.length,
                  itemBuilder: (context, index) {
                    final item = orderItems[index];
                    return ListTile(
                      leading: item['image_url'] != null
                          ? Image.network('http://localhost/clothing_project/tonbaongu/API/' + item['image_url'], width: 40)
                          : null,
                      title: Text(item['product_name'] ?? ''),
                      subtitle: Text('Màu: ${item['color']}, Size: ${item['size']}, Chất liệu: ${item['material']}'),
                      trailing: Text('x${item['quantity']} - ${item['price']} VNĐ'),
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