import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddEditVariantScreen extends StatefulWidget {
  final ProductVariant? variant;
  final int productId;

  const AddEditVariantScreen({
    Key? key,
    this.variant,
    required this.productId,
  }) : super(key: key);

  @override
  State<AddEditVariantScreen> createState() => _AddEditVariantScreenState();
}

class _AddEditVariantScreenState extends State<AddEditVariantScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController skuController;
  late TextEditingController priceController;
  late TextEditingController stockController;
  late TextEditingController imageUrlController;
  String? selectedStatus;
  bool isLoading = false;
  bool isDropdownLoading = true;
  List<String> statuses = ['active', 'inactive', 'out_of_stock'];

  // Thuộc tính động
  List<Map<String, dynamic>> attributes = [];
  Map<int, List<Map<String, dynamic>>> attributeValues = {}; // attribute_id -> List<value>
  Map<int, int?> selectedValueIds = {}; // attribute_id -> value_id

  @override
  void initState() {
    super.initState();
    skuController = TextEditingController(text: widget.variant?.sku ?? '');
    priceController = TextEditingController(text: widget.variant?.price.toString() ?? '');
    stockController = TextEditingController(text: widget.variant?.stock.toString() ?? '');
    imageUrlController = TextEditingController(text: widget.variant?.imageUrl ?? '');
    selectedStatus = widget.variant?.status ?? statuses.first;
    _loadAttributesAndValues();
  }

  Future<void> _loadAttributesAndValues() async {
    setState(() { isDropdownLoading = true; });
    try {
      // Lấy danh sách thuộc tính
      final attrRes = await http.get(Uri.parse('http://localhost/EcommerceClothingApp/API/variants_attributes/get_attributes.php'));
      final attrData = json.decode(attrRes.body);
      if (attrData['success'] == true) {
        attributes = List<Map<String, dynamic>>.from(attrData['attributes']);
        // Lấy giá trị cho từng thuộc tính
        for (var attr in attributes) {
          final attrId = attr['id'];
          final valRes = await http.get(Uri.parse('http://localhost/EcommerceClothingApp/API/variants_attributes/get_attribute_values.php?attribute_id=$attrId'));
          final valData = json.decode(valRes.body);
          if (valData['success'] == true) {
            attributeValues[attrId] = List<Map<String, dynamic>>.from(valData['values']);
          } else {
            attributeValues[attrId] = [];
          }
        }
        // Nếu là sửa, map giá trị đã chọn
        if (widget.variant != null) {
          for (var av in widget.variant!.attributeValues) {
            selectedValueIds[av.attributeId] = av.valueId;
          }
        } else {
          for (var attr in attributes) {
            selectedValueIds[attr['id']] = null;
          }
        }
      }
      setState(() { isDropdownLoading = false; });
    } catch (e) {
      setState(() { isDropdownLoading = false; });
    }
  }

  Future<void> _saveVariant() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedValueIds.values.any((v) => v == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn đầy đủ giá trị cho tất cả thuộc tính!'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() { isLoading = true; });
    try {
      final url = widget.variant == null
          ? 'http://localhost/EcommerceClothingApp/API/variants_attributes/add_variant.php'
          : 'http://localhost/EcommerceClothingApp/API/variants_attributes/update_variant.php';
      final data = {
        if (widget.variant != null) 'variant_id': widget.variant!.id,
        'product_id': widget.productId,
        'sku': skuController.text.trim(),
        'attribute_value_ids': selectedValueIds.values.toList(),
        'price': double.parse(priceController.text),
        'stock': int.parse(stockController.text),
        'image_url': imageUrlController.text.isNotEmpty ? imageUrlController.text : null,
        'status': selectedStatus,
      };
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message']), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Lỗi không xác định'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() { isLoading = false; });
    }
  }

  Widget _buildAttributeDropdown(Map<String, dynamic> attr) {
    final attrId = attr['id'];
    final attrName = attr['name'];
    final values = attributeValues[attrId] ?? [];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<int>(
        value: selectedValueIds[attrId],
        decoration: InputDecoration(labelText: attrName, border: OutlineInputBorder()),
        items: values.map<DropdownMenuItem<int>>((item) => DropdownMenuItem(
          value: item['value_id'],
          child: Text(item['value']),
        )).toList(),
        onChanged: (val) => setState(() => selectedValueIds[attrId] = val),
        validator: (val) => val == null ? 'Vui lòng chọn $attrName' : null,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType? keyboardType, int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.variant == null ? "Thêm biến thể" : "Sửa biến thể"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isDropdownLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thông tin biến thể', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo[800])),
                    const SizedBox(height: 20),
                    _buildTextField(skuController, "SKU *", validator: (v) => v!.isEmpty ? "SKU không được để trống" : null),
                    ...attributes.map(_buildAttributeDropdown).toList(),
                    _buildTextField(priceController, "Giá *", keyboardType: TextInputType.number, validator: (value) {
                      if (value!.isEmpty) return "Giá không được để trống";
                      if (double.tryParse(value) == null) return "Giá phải là số";
                      if (double.parse(value) <= 0) return "Giá phải lớn hơn 0";
                      return null;
                    }),
                    _buildTextField(stockController, "Tồn kho *", keyboardType: TextInputType.number, validator: (value) {
                      if (value!.isEmpty) return "Tồn kho không được để trống";
                      if (int.tryParse(value) == null) return "Tồn kho phải là số";
                      if (int.parse(value) < 0) return "Tồn kho không được âm";
                      return null;
                    }),
                    _buildTextField(imageUrlController, "Link hình ảnh"),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(labelText: 'Trạng thái', border: OutlineInputBorder()),
                        items: statuses.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                        onChanged: (val) => setState(() => selectedStatus = val),
                        validator: (val) => val == null || val.isEmpty ? 'Vui lòng chọn trạng thái' : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _saveVariant,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(widget.variant == null ? "Thêm biến thể" : "Lưu thay đổi"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 