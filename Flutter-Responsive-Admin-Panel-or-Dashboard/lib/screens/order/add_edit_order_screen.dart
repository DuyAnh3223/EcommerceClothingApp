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
  late TextEditingController maDHController;
  late TextEditingController maNDController;
  late TextEditingController ngayDatHangController;
  late TextEditingController tongGiaTriController;
  late TextEditingController trangThaiController;

  @override
  void initState() {
    super.initState();
    maDHController = TextEditingController(text: widget.order?.maDH ?? '');
    maNDController = TextEditingController(text: widget.order?.maND ?? '');
    ngayDatHangController = TextEditingController(text: widget.order?.ngayDatHang ?? '');
    tongGiaTriController = TextEditingController(text: widget.order?.tongGiaTri.toString() ?? '');
    trangThaiController = TextEditingController(text: widget.order?.trangThaiDonHang ?? '');
  }

  @override
  void dispose() {
    maDHController.dispose();
    maNDController.dispose();
    ngayDatHangController.dispose();
    tongGiaTriController.dispose();
    trangThaiController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final newOrder = Order(
        maDH: widget.order?.maDH ?? '',
        maND: maNDController.text,
        ngayDatHang: ngayDatHangController.text,
        tongGiaTri: double.tryParse(tongGiaTriController.text) ?? 0.0,
        trangThaiDonHang: trangThaiController.text,
      );

      String url;
      Map<String, dynamic> body;

      if (widget.order == null) {
        url = 'http://localhost/MyProject/backendapi/orders/add_order.php';
        body = newOrder.toJson();
      } else {
        url = 'http://localhost/MyProject/backendapi/orders/update_order.php';
        body = newOrder.toJson();
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
                _buildField(maDHController, "Mã đơn hàng", enabled: false),
              _buildField(maNDController, "Mã người dùng", keyboardType: TextInputType.number),
              _buildField(ngayDatHangController, "Ngày đặt hàng (yyyy-mm-dd)"),
              _buildField(tongGiaTriController, "Tổng giá trị", keyboardType: TextInputType.number),
              _buildField(trangThaiController, "Trạng thái đơn hàng"),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _save, child: const Text("Lưu")),
            ],
          ),
        ),
      ),
    );
  }
}
