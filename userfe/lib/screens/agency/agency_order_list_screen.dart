import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';

class AgencyOrderListScreen extends StatefulWidget {
  const AgencyOrderListScreen({Key? key}) : super(key: key);

  @override
  State<AgencyOrderListScreen> createState() => _AgencyOrderListScreenState();
}

class _AgencyOrderListScreenState extends State<AgencyOrderListScreen> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
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
      await _loadOrders();
    }
  }

  Future<void> _loadOrders() async {
    if (userData == null) return;
    setState(() {
      isLoading = true;
    });
    final result = await OrderService.getAgencyOrders(agencyId: userData!['id']);
    if (mounted) {
      setState(() {
        isLoading = false;
        if (result['success'] == true && result['data'] != null) {
          orders = List<Map<String, dynamic>>.from(result['data']);
        } else {
          orders = [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng đã bán'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text('Chưa có đơn hàng nào được bán!'))
              : ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return ListTile(
                      leading: Text('#${order['order_id']}'),
                      title: Text(order['product_name'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Số lượng: ${order['quantity']}'),
                          Text('Trạng thái: ${order['status']}'),
                          Text('Ngày bán: ${order['order_date']}'),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
} 