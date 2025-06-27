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
  List<OrderItem> items = [];
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
      final response = await http.get(Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/orders/get_order_items.php?order_id=${widget.order.id}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] is List) {
          items = (data['data'] as List).map((e) => OrderItem.fromJson(e)).toList();
        } else {
          errorMessage = data['message'] ?? 'Lỗi không xác định';
        }
      } else {
        errorMessage = 'Lỗi kết nối API: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage = 'Lỗi khi load sản phẩm: $e';
    }
    setState(() {
      isLoading = false;
    });
  }

  void _editOrder() async {
    // TODO: Mở màn hình sửa đơn hàng nếu cần
  }

  void _deleteOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Bạn có chắc chắn muốn xóa đơn hàng #${widget.order.id}?'),
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
          body: json.encode({'id': widget.order.id}),
        );
        final data = json.decode(response.body);
        if (data['success'] == true) {
          Navigator.pop(context, true);
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
      appBar: AppBar(
        title: Text('Đơn hàng #${widget.order.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: _editOrder,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteOrder,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Khách hàng: ${widget.order.userName ?? ''} (ID: ${widget.order.userId})'),
                      Text('Địa chỉ ID: ${widget.order.addressId}'),
                      Text('Ngày đặt: ${widget.order.orderDate}'),
                      Text('Trạng thái: ${widget.order.status}'),
                      Text('Tổng tiền: ${widget.order.totalAmount} VNĐ'),
                      const SizedBox(height: 16),
                      const Text('Danh sách sản phẩm:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...items.map((item) => ListTile(
                            leading: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                ? Image.network(
                                    'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=${item.imageUrl}',
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.image_not_supported),
                            title: Text(item.productName ?? ''),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.variant != null && item.variant!.isNotEmpty)
                                  Text(item.variant!),
                                Text('Số lượng: ${item.quantity} | Giá: ${item.price}'),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
    );
  }
}

class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final int variantId;
  final int quantity;
  final double price;
  final String? productName;
  final String? variant;
  final String? imageUrl;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.variantId,
    required this.quantity,
    required this.price,
    this.productName,
    this.variant,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      variantId: json['variant_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      productName: json['product_name'],
      variant: json['variant'],
      imageUrl: json['image_url'],
    );
  }
}