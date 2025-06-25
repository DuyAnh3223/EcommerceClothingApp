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
  
  String selectedColor = 'black';
  String selectedSize = 'M';
  String selectedStatus = 'active';
  String selectedMaterial = 'Cotton';
  
  bool isLoading = false;

  final List<String> colors = [
    'white', 'black', 'purple', 'pink', 'blue', 'silver',
    'red', 'yellow', 'green', 'brown', 'gray', 'orange'
  ];
  
  final List<String> sizes = ['S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
  
  final List<String> statuses = ['active', 'inactive', 'out_of_stock'];

  final List<String> materials = [
    'Cotton', 'Linen', 'Wool', 'Polyester', 'Denim', 'Leather', 'Silk', 'Nylon'
  ];

  @override
  void initState() {
    super.initState();
    
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

    setState(() {
      isLoading = true;
    });

    try {
      final url = widget.variant == null
          ? 'http://localhost/clothing_project/tonbaongu/API/products/add_variant.php'
          : 'http://localhost/clothing_project/tonbaongu/API/products/update_variant.php';

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

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'])),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? 'Lỗi không xác định')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.variant == null ? "Thêm biến thể" : "Sửa biến thể"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thông tin biến thể',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[800],
                ),
              ),
              const SizedBox(height: 20),
              
              // Color dropdown
              _buildDropdown(
                'Màu sắc *',
                selectedColor,
                colors,
                (value) {
                  setState(() {
                    selectedColor = value!;
                  });
                },
              ),
              
              // Size dropdown
              _buildDropdown(
                'Kích thước *',
                selectedSize,
                sizes,
                (value) {
                  setState(() {
                    selectedSize = value!;
                  });
                },
              ),
              
              // Price field
              _buildTextField(
                priceController,
                "Giá *",
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return "Giá không được để trống";
                  if (double.tryParse(value) == null) return "Giá phải là số";
                  if (double.parse(value) <= 0) return "Giá phải lớn hơn 0";
                  return null;
                },
              ),
              
              // Stock field
              _buildTextField(
                stockController,
                "Tồn kho *",
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return "Tồn kho không được để trống";
                  if (int.tryParse(value) == null) return "Tồn kho phải là số";
                  if (int.parse(value) < 0) return "Tồn kho không được âm";
                  return null;
                },
              ),
              
              // Image URL field
              _buildTextField(
                imageUrlController,
                "Link hình ảnh",
              ),
              
              // Status dropdown
              _buildDropdown(
                'Trạng thái *',
                selectedStatus,
                statuses,
                (value) {
                  setState(() {
                    selectedStatus = value!;
                  });
                },
              ),
              
              // Material dropdown
              _buildDropdown(
                'Chất liệu *',
                selectedMaterial,
                materials,
                (value) {
                  setState(() {
                    selectedMaterial = value!;
                  });
                },
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
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.variant == null ? "Thêm biến thể" : "Cập nhật biến thể",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.indigo[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.indigo[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.indigo[600]!, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        style: TextStyle(
          color: Colors.blue,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.indigo[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.indigo[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.indigo[600]!, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        dropdownColor: Colors.white,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? "Vui lòng chọn $label" : null,
      ),
    );
  }
} 