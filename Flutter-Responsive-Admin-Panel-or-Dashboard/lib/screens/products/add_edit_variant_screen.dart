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
  
  late TextEditingController priceController;
  late TextEditingController stockController;
  late TextEditingController imageUrlController;
  
  String? selectedColor;
  String? selectedSize;
  String? selectedStatus;
  String? selectedMaterial;
  
  bool isLoading = false;
  bool isDropdownLoading = true;

  List<String> colors = [];
  List<String> sizes = [];
  List<String> statuses = ['active', 'inactive', 'out_of_stock'];
  List<String> materials = [];

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
    if (widget.variant != null) {
      // Edit mode
      priceController = TextEditingController(text: widget.variant!.price.toString());
      stockController = TextEditingController(text: widget.variant!.stock.toString());
      imageUrlController = TextEditingController(text: widget.variant!.imageUrl ?? '');
      selectedColor = widget.variant!.color;
      selectedSize = widget.variant!.size;
      selectedStatus = widget.variant!.status;
      selectedMaterial = widget.variant!.material;
    } else {
      // Add mode
      priceController = TextEditingController();
      stockController = TextEditingController();
      imageUrlController = TextEditingController();
      selectedStatus = statuses.first;
    }
  }

  Future<void> _loadDropdownData() async {
    setState(() { isDropdownLoading = true; });
    try {
      // Giả sử có các API get_colors.php, get_sizes.php, get_materials.php
      // Nếu chưa có, mock dữ liệu
      // final colorRes = await http.get(Uri.parse('http://localhost/API/get_colors.php'));
      // final sizeRes = await http.get(Uri.parse('http://localhost/API/get_sizes.php'));
      // final materialRes = await http.get(Uri.parse('http://localhost/API/get_materials.php'));
      // colors = List<String>.from(json.decode(colorRes.body)['data']);
      // sizes = List<String>.from(json.decode(sizeRes.body)['data']);
      // materials = List<String>.from(json.decode(materialRes.body)['data']);
      await Future.delayed(const Duration(milliseconds: 300));
      colors = ['white', 'black', 'purple', 'pink', 'blue', 'silver', 'red', 'yellow', 'green', 'brown', 'gray', 'orange'];
      sizes = ['S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
      materials = ['Cotton', 'Linen', 'Wool', 'Polyester', 'Denim', 'Leather', 'Silk', 'Nylon'];
      setState(() { isDropdownLoading = false; });
    } catch (e) {
      setState(() { isDropdownLoading = false; });
    }
  }

  @override
  void dispose() {
    priceController.dispose();
    stockController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveVariant() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { isLoading = true; });
    try {
      final url = widget.variant == null
          ? 'http://localhost/EcommerceClothingApp/API/products/add_variant.php'
          : 'http://localhost/EcommerceClothingApp/API/products/update_variant.php';
      final data = {
        if (widget.variant != null) 'variant_id': widget.variant!.id,
        'product_id': widget.productId,
        'color': selectedColor,
        'size': selectedSize,
        'price': double.parse(priceController.text),
        'stock': int.parse(stockController.text),
        'image_url': imageUrlController.text.isNotEmpty ? imageUrlController.text : null,
        'status': selectedStatus,
        'material': selectedMaterial,
      };
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      
      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message']),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Lỗi không xác định'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Hiển thị thông báo lỗi từ API cho tất cả status codes khác
        String errorMessage = 'Lỗi không xác định';
        if (responseData['message'] != null) {
          errorMessage = responseData['message'];
        } else {
          switch (response.statusCode) {
            case 400:
              errorMessage = 'Dữ liệu không hợp lệ';
              break;
            case 404:
              errorMessage = 'Không tìm thấy tài nguyên';
              break;
            case 409:
              errorMessage = 'Biến thể đã tồn tại';
              break;
            case 500:
              errorMessage = 'Lỗi máy chủ';
              break;
            default:
              errorMessage = 'Lỗi kết nối: ${response.statusCode}';
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() { isLoading = false; });
    }
  }

  Widget _buildDropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        validator: (val) => val == null || val.isEmpty ? 'Vui lòng chọn $label' : null,
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
                    _buildDropdown('Màu sắc *', selectedColor, colors, (value) => setState(() => selectedColor = value)),
                    _buildDropdown('Kích thước *', selectedSize, sizes, (value) => setState(() => selectedSize = value)),
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
                    _buildDropdown('Trạng thái *', selectedStatus, statuses, (value) => setState(() => selectedStatus = value)),
                    _buildDropdown('Chất liệu *', selectedMaterial, materials, (value) => setState(() => selectedMaterial = value)),
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