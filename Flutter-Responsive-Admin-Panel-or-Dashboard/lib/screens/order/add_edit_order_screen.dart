import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/order_model.dart';

class AddEditOrderScreen extends StatefulWidget {
  final Order? order;

  const AddEditOrderScreen({super.key, this.order});

  @override
  State<AddEditOrderScreen> createState() => _AddEditOrderScreenState();
}

class _AddEditOrderScreenState extends State<AddEditOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController idController;
  late TextEditingController userIdController;
  late TextEditingController userNameController;
  late TextEditingController addressIdController;
  late TextEditingController orderDateController;
  late TextEditingController totalAmountController;
  late TextEditingController statusController;
  late String statusValue;

  @override
  void initState() {
    super.initState();
    idController = TextEditingController(text: widget.order?.id.toString() ?? '');
    userIdController = TextEditingController(text: widget.order?.userId.toString() ?? '');
    userNameController = TextEditingController(text: widget.order?.userName ?? '');
    addressIdController = TextEditingController(text: widget.order?.addressId.toString() ?? '');
    orderDateController = TextEditingController(text: widget.order?.orderDate ?? '');
    totalAmountController = TextEditingController(text: widget.order?.totalAmount.toString() ?? '');
    statusValue = widget.order?.status ?? 'pending';
    statusController = TextEditingController(text: statusValue);
  }

  @override
  void dispose() {
    idController.dispose();
    userIdController.dispose();
    userNameController.dispose();
    addressIdController.dispose();
    orderDateController.dispose();
    totalAmountController.dispose();
    statusController.dispose();
    super.dispose();
  }

  void _saveOrder() async {
    if (_formKey.currentState!.validate()) {
      final newOrder = Order(
        id: int.tryParse(idController.text) ?? 0,
        userId: int.tryParse(userIdController.text) ?? 0,
        userName: userNameController.text,
        addressId: int.tryParse(addressIdController.text) ?? 0,
        orderDate: orderDateController.text,
        totalAmount: double.tryParse(totalAmountController.text) ?? 0.0,
        status: statusValue,
      );

      String url;
      String method;
      Map<String, dynamic> body;

      if (widget.order == null) {
        url = 'http://127.0.0.1/EcommerceClothingApp/API/orders/add_order.php';
        method = 'POST';
        body = newOrder.toJson();
      } else {
        url = 'http://127.0.0.1/EcommerceClothingApp/API/orders/update_order.php';
        method = 'POST';
        body = {
          'order_id': widget.order!.id,
          'status': statusValue,
        };
      }

      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );

        final data = json.decode(response.body);
        if (data['success'] == true) {
          Navigator.pop(context, newOrder);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${data['message']}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e')),
        );
      }
    }
  }

  Widget _buildField(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.text, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: keyboardType,
        enabled: enabled,
        validator: (value) => value == null || value.isEmpty ? "Không được để trống" : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.order == null ? "Thêm đơn hàng" : "Sửa đơn hàng")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (widget.order != null)
                _buildField(idController, "Mã đơn hàng", enabled: false),
              _buildField(userIdController, "Mã người dùng", keyboardType: TextInputType.number),
              _buildField(userNameController, "Tên người dùng"),
              _buildField(addressIdController, "Mã địa chỉ", keyboardType: TextInputType.number),
              _buildField(totalAmountController, "Tổng giá trị", keyboardType: TextInputType.number),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: statusValue,
                  decoration: const InputDecoration(labelText: "Trạng thái đơn hàng"),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Chờ xác nhận')),
                    DropdownMenuItem(value: 'confirmed', child: Text('Đã xác nhận')),
                    DropdownMenuItem(value: 'shipping', child: Text('Đang giao hàng')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      statusValue = value ?? 'pending';
                    });
                  },
                  validator: (value) => value == null || value.isEmpty ? "Không được để trống" : null,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _saveOrder, child: const Text("Lưu")),
            ],
          ),
        ),
      ),
    );
  }
}
