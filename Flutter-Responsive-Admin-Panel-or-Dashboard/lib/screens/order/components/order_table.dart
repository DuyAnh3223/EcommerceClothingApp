import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../models/order_model.dart';
import '../add_edit_order_screen.dart';

class OrderTable extends StatelessWidget {
  final List<Order> orders;
  final Function onReload;

  const OrderTable({Key? key, required this.orders, required this.onReload}) : super(key: key);

  Future<void> _deleteOrder(BuildContext context, String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận"),
        content: const Text("Bạn có chắc chắn muốn xóa đơn hàng này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Xóa")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.post(
          Uri.parse("http://localhost/MyProject/backendapi/orders/delete_order.php"),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'MaDH': orderId}),
        );

        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Xóa đơn hàng thành công")),
            );
            onReload();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Lỗi: ${result['message']}")),
            );
          }
        } else {
          throw Exception("Kết nối thất bại");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi xóa: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Mã đơn')),
          DataColumn(label: Text('Mã người dùng')),
          DataColumn(label: Text('Ngày đặt')),
          DataColumn(label: Text('Tổng giá trị')),
          DataColumn(label: Text('Trạng thái')),
          DataColumn(label: Text('Hành động')),
        ],
        rows: orders.map((order) {
          return DataRow(cells: [
            DataCell(Text(order.maDH)),
            DataCell(Text(order.maND)),
            DataCell(Text(order.ngayDatHang)),
            DataCell(Text(order.tongGiaTri.toString())),
            DataCell(Text(order.trangThaiDonHang)),
            DataCell(Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    final updatedOrder = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditOrderScreen(order: order),
                      ),
                    );
                    if (updatedOrder != null) onReload();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteOrder(context, order.maDH),
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }
}
