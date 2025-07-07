import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VoucherAdminScreen extends StatefulWidget {
  const VoucherAdminScreen({Key? key}) : super(key: key);

  @override
  State<VoucherAdminScreen> createState() => _VoucherAdminScreenState();
}

class _VoucherAdminScreenState extends State<VoucherAdminScreen> {
  List vouchers = [];
  bool isLoading = false;
  String apiUrl = 'http://localhost/EcommerceClothingApp/API/admin/vouchers/get_vouchers.php';

  @override
  void initState() {
    super.initState();
    fetchVouchers();
  }

  Future<void> fetchVouchers() async {
    setState(() => isLoading = true);
    final response = await http.get(Uri.parse(apiUrl), headers: {'Authorization': 'Bearer admin_token'});
    if (response.statusCode == 200) {
      setState(() {
        vouchers = json.decode(response.body)['data'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải voucher: ${response.body}')));
    }
  }

  void showVoucherDialog({Map? voucher}) {
    final _formKey = GlobalKey<FormState>();
    final codeController = TextEditingController(text: voucher?['voucher_code'] ?? '');
    final discountController = TextEditingController(text: voucher?['discount_amount']?.toString() ?? '');
    final quantityController = TextEditingController(text: voucher?['quantity']?.toString() ?? '');
    final minQuantityController = TextEditingController(text: voucher?['min_quantity']?.toString() ?? '1');
    final minTotalController = TextEditingController(text: voucher?['min_total_amount']?.toString() ?? '0');
    final startDateController = TextEditingController(text: voucher?['start_date'] ?? '');
    final endDateController = TextEditingController(text: voucher?['end_date'] ?? '');
    final status = ValueNotifier<String>(voucher?['status'] ?? 'active');
    final voucherType = ValueNotifier<String>(voucher?['voucher_type'] ?? 'all_products');
    final categoryController = TextEditingController(text: voucher?['category_filter'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(voucher == null ? 'Thêm voucher' : 'Sửa voucher'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeController,
                  decoration: InputDecoration(labelText: 'Mã voucher'),
                  validator: (v) => v == null || v.isEmpty ? 'Nhập mã' : null,
                ),
                TextFormField(
                  controller: discountController,
                  decoration: InputDecoration(labelText: 'Số tiền giảm'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || double.tryParse(v) == null ? 'Nhập số' : null,
                ),
                TextFormField(
                  controller: quantityController,
                  decoration: InputDecoration(labelText: 'Số lượng'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || int.tryParse(v) == null ? 'Nhập số' : null,
                ),
                TextFormField(
                  controller: minQuantityController,
                  decoration: InputDecoration(labelText: 'Số lượng tối thiểu'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || int.tryParse(v) == null ? 'Nhập số' : null,
                ),
                TextFormField(
                  controller: minTotalController,
                  decoration: InputDecoration(labelText: 'Tổng tiền tối thiểu'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || double.tryParse(v) == null ? 'Nhập số' : null,
                ),
                TextFormField(
                  controller: startDateController,
                  decoration: InputDecoration(labelText: 'Ngày bắt đầu (YYYY-MM-DD HH:mm:ss)'),
                  validator: (v) => v == null || v.isEmpty ? 'Nhập ngày' : null,
                ),
                TextFormField(
                  controller: endDateController,
                  decoration: InputDecoration(labelText: 'Ngày kết thúc (YYYY-MM-DD HH:mm:ss)'),
                  validator: (v) => v == null || v.isEmpty ? 'Nhập ngày' : null,
                ),
                ValueListenableBuilder<String>(
                  valueListenable: status,
                  builder: (context, value, _) => DropdownButtonFormField<String>(
                    value: value,
                    decoration: InputDecoration(labelText: 'Trạng thái'),
                    items: [
                      DropdownMenuItem(value: 'active', child: Text('active')),
                      DropdownMenuItem(value: 'inactive', child: Text('inactive')),
                      DropdownMenuItem(value: 'expired', child: Text('expired')),
                    ],
                    onChanged: (v) => status.value = v ?? 'active',
                  ),
                ),
                ValueListenableBuilder<String>(
                  valueListenable: voucherType,
                  builder: (context, value, _) => DropdownButtonFormField<String>(
                    value: value,
                    decoration: InputDecoration(labelText: 'Loại voucher'),
                    items: [
                      DropdownMenuItem(value: 'all_products', child: Text('Tất cả sản phẩm')),
                      DropdownMenuItem(value: 'specific_products', child: Text('Sản phẩm cụ thể')),
                      DropdownMenuItem(value: 'category_based', child: Text('Theo danh mục')),
                    ],
                    onChanged: (v) => voucherType.value = v ?? 'all_products',
                  ),
                ),
                TextFormField(
                  controller: categoryController,
                  decoration: InputDecoration(labelText: 'Danh mục áp dụng (nếu có)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final data = {
                  'voucher_code': codeController.text.trim(),
                  'discount_amount': double.parse(discountController.text),
                  'quantity': int.parse(quantityController.text),
                  'min_quantity': int.parse(minQuantityController.text),
                  'min_total_amount': double.parse(minTotalController.text),
                  'start_date': startDateController.text.trim(),
                  'end_date': endDateController.text.trim(),
                  'status': status.value,
                  'voucher_type': voucherType.value,
                  'category_filter': categoryController.text.trim(),
                };
                if (voucher == null) {
                  await addVoucher(data);
                } else {
                  data['id'] = voucher['id'];
                  await updateVoucher(data);
                }
                Navigator.pop(context);
                fetchVouchers();
              }
            },
            child: Text(voucher == null ? 'Thêm' : 'Cập nhật'),
          ),
        ],
      ),
    );
  }

  Future<void> addVoucher(Map data) async {
    final response = await http.post(
      Uri.parse('http://localhost/EcommerceClothingApp/API/admin/vouchers/add_voucher.php'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer admin_token'},
      body: json.encode(data),
    );
    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Thêm voucher thành công!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${response.body}')));
    }
  }

  Future<void> updateVoucher(Map data) async {
    final response = await http.put(
      Uri.parse('http://localhost/EcommerceClothingApp/API/admin/vouchers/update_voucher.php'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer admin_token'},
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cập nhật thành công!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${response.body}')));
    }
  }

  Future<void> deleteVoucher(int id) async {
    final response = await http.delete(
      Uri.parse('http://localhost/EcommerceClothingApp/API/admin/vouchers/delete_voucher.php'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer admin_token'},
      body: json.encode({'id': id}),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xóa voucher!')));
      fetchVouchers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${response.body}')));
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quản lý Voucher (Admin)')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showVoucherDialog(),
        child: Icon(Icons.add),
        tooltip: 'Thêm voucher',
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Mã')),
                  DataColumn(label: Text('Giảm')),
                  DataColumn(label: Text('Số lượng')),
                  DataColumn(label: Text('SL tối thiểu')),
                  DataColumn(label: Text('Tiền tối thiểu')),
                  DataColumn(label: Text('Loại')),
                  DataColumn(label: Text('Danh mục')),
                  DataColumn(label: Text('Sản phẩm')),
                  DataColumn(label: Text('Bắt đầu')),
                  DataColumn(label: Text('Kết thúc')),
                  DataColumn(label: Text('Hành động')),
                ],
                rows: vouchers.map<DataRow>((v) {
                  final used = v['used'] ?? (v['quantity'] != null && v['remaining'] != null ? v['quantity'] - v['remaining'] : '-');
                  final remaining = v['remaining'] ?? v['quantity'];
                  String typeText = v['voucher_type'] == 'all_products'
                      ? 'Tất cả'
                      : (v['voucher_type'] == 'specific_products' ? 'Cụ thể' : 'Danh mục');
                  String category = v['category_filter'] ?? '';
                  String products = v['associated_product_names'] != null ? (v['associated_product_names'] as List).join(', ') : '';
                  return DataRow(cells: [
                    DataCell(Text('${v['id']}')),
                    DataCell(Row(
                      children: [
                        Text('${v['voucher_code']}', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 6),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor(v['status'] ?? ''),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            v['status'] ?? '',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    )),
                    DataCell(Text('${v['discount_amount']}đ')),
                    DataCell(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tổng: ${v['quantity']}'),
                        Text('Còn: $remaining', style: TextStyle(fontSize: 11, color: Colors.green)),
                        Text('Đã dùng: $used', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
                      ],
                    )),
                    DataCell(Text('${v['min_quantity']}')),
                    DataCell(Text('${v['min_total_amount']}đ')),
                    DataCell(Text(typeText)),
                    DataCell(Text(category)),
                    DataCell(Text(products)),
                    DataCell(Text('${v['start_date']}')),
                    DataCell(Text('${v['end_date']}')),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => showVoucherDialog(voucher: v),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteVoucher(v['id']),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
    );
  }
} 