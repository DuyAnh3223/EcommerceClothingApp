// ========== Cấu trúc JSON giống User =================
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/product_model.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController categoryController;
  late TextEditingController genderTargetController;

  String selectedCategory = 'T-Shirts';
  String selectedGenderTarget = 'unisex';

  final List<String> categories = [
    'T-Shirts',
    'Shirts',
    'Jackets & Coats',
    'Pants',
    'Shorts',
    'Knitwear',
    'Suits & Blazers',
    'Hoodies',
    'Underwear',
    'Loungewear'
  ];

  final List<String> genderTargets = [
    'male',
    'female',
    'kids',
    'unisex'
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product?.name ?? '');
    descriptionController = TextEditingController(text: widget.product?.description ?? '');
    categoryController = TextEditingController(text: widget.product?.category ?? 'T-Shirts');
    genderTargetController = TextEditingController(text: widget.product?.genderTarget ?? 'unisex');
    
    selectedCategory = widget.product?.category ?? 'T-Shirts';
    selectedGenderTarget = widget.product?.genderTarget ?? 'unisex';
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    genderTargetController.dispose();
    super.dispose();
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final productData = {
        'name': nameController.text,
        'description': descriptionController.text,
        'category': selectedCategory,
        'gender_target': selectedGenderTarget,
      };

      String url;
      String method;

      if (widget.product == null) {
        // Add new product
        url = 'http://localhost/clothing_project/tonbaongu/API/products/add_product.php';
        method = 'POST';
      } else {
        // Update existing product
        url = 'http://localhost/clothing_project/tonbaongu/API/products/update_product.php';
        method = 'POST';
        productData['id'] = widget.product!.id.toString(); // Convert int to String
      }

      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(productData),
        );

        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'])),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Lỗi không xác định')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? "Thêm sản phẩm" : "Sửa sản phẩm"),
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
              if (widget.product != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thông tin sản phẩm hiện tại',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('ID: ${widget.product!.id}'),
                        Text('Tên: ${widget.product!.name}'),
                        Text('Danh mục: ${widget.product!.category}'),
                        Text('Đối tượng: ${widget.product!.genderTarget}'),
                        Text('Số biến thể: ${widget.product!.variants.length}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              Text(
                'Thông tin cơ bản',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[800],
                ),
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                nameController,
                "Tên sản phẩm *",
                validator: (value) => value!.isEmpty ? "Tên sản phẩm không được để trống" : null,
              ),
              
              _buildTextField(
                descriptionController,
                "Mô tả",
                maxLines: 3,
              ),
              
              const SizedBox(height: 16),
              Text(
                'Danh mục và đối tượng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[700],
                ),
              ),
              const SizedBox(height: 12),
              
              _buildDropdown(
                'Danh mục *',
                selectedCategory,
                categories,
                (value) {
                  setState(() {
                    selectedCategory = value!;
                  });
                },
              ),
              
              const SizedBox(height: 12),
              
              _buildDropdown(
                'Đối tượng *',
                selectedGenderTarget,
                genderTargets,
                (value) {
                  setState(() {
                    selectedGenderTarget = value!;
                  });
                },
              ),
              
              const SizedBox(height: 20),
              
              if (widget.product != null && widget.product!.variants.isNotEmpty) ...[
                Card(
                  color: Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Lưu ý',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sản phẩm này có ${widget.product!.variants.length} biến thể. '
                          'Việc thay đổi thông tin sản phẩm sẽ không ảnh hưởng đến các biến thể hiện có.',
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    widget.product == null ? "Thêm sản phẩm" : "Cập nhật sản phẩm",
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
    int maxLines = 1,
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
            color: Colors.indigo[600],
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
          fillColor: Colors.grey[50],
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator ?? (value) => value!.isEmpty ? "Trường này không được để trống" : null,
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
          fillColor: Colors.white, // màu background của input
        ),
        dropdownColor: Colors.white, // màu background của dropdown menu
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: TextStyle(
                color: Colors.black, // màu text của dropdown
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

