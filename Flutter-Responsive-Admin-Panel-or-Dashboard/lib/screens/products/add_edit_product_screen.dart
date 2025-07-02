// ========== Cấu trúc JSON giống User =================
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/product_model.dart';
import '../../services/image_service.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

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
  File? _selectedImage;
  Uint8List? _imageBytes;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  bool _shouldRemoveImage = false;

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        final file = File(image.path);
        final bytes = await image.readAsBytes();
        
        setState(() {
          _selectedImage = file;
          _imageBytes = bytes;
          _shouldRemoveImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn hình ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null || _imageBytes == null) {
      return null;
    }

    if (mounted) {
      setState(() {
        _isUploading = true;
      });
    }

    try {
      final result = await ImageService.uploadImageFromBytes(_imageBytes!);

      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }

      if (result['success']) {
        return result['image_url'];
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload thất bại: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      // Upload hình ảnh trước nếu có hình ảnh mới được chọn
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage();
        if (imageUrl == null) {
          return; // Dừng nếu upload thất bại
        }
      }

      final productData = <String, dynamic>{
        'name': nameController.text,
        'description': descriptionController.text,
        'category': selectedCategory,
        'gender_target': selectedGenderTarget,
      };

      // Xử lý main_image
      if (widget.product == null) {
        // Thêm sản phẩm mới: chỉ thêm main_image nếu có hình ảnh mới
        if (imageUrl != null) {
          productData['main_image'] = imageUrl;
        }
      } else {
        // Cập nhật sản phẩm: 
        if (imageUrl != null) {
          // Có hình ảnh mới được upload
          productData['main_image'] = imageUrl;
        } else if (_shouldRemoveImage) {
          // Người dùng muốn xóa hình ảnh
          productData['main_image'] = null;
        } else if (widget.product!.mainImage != null && widget.product!.mainImage!.isNotEmpty) {
          // Giữ nguyên hình ảnh cũ
          productData['main_image'] = widget.product!.mainImage!;
        }
        // Nếu không có hình ảnh cũ và không có hình ảnh mới, thì không gửi main_image
      }

      String url;
      String method;

      if (widget.product == null) {
        // Add new product
        url = 'http://127.0.0.1/EcommerceClothingApp/API/admin/products/add_product.php';
        method = 'POST';
      } else {
        // Update existing product
        url = 'http://127.0.0.1/EcommerceClothingApp/API/admin/products/update_product.php';
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
              
              // Hình ảnh sản phẩm
              Text(
                'Hình ảnh sản phẩm',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[700],
                ),
              ),
              const SizedBox(height: 12),
              
              // Image Preview
              GestureDetector(
                onTap: () {
                  // Hiển thị hình ảnh full size khi click
                  if (_imageBytes != null || 
                      (widget.product != null && widget.product!.mainImage != null && widget.product!.mainImage!.isNotEmpty)) {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                            maxHeight: MediaQuery.of(context).size.height * 0.8,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppBar(
                                title: const Text('Xem hình ảnh'),
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                actions: [
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                              Expanded(
                                child: _imageBytes != null
                                    ? Image.memory(
                                        _imageBytes!,
                                        fit: BoxFit.contain,
                                      )
                                    : Image.network(
                                        'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=${widget.product!.mainImage!}',
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) => const Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.error, size: 64, color: Colors.red),
                                              SizedBox(height: 8),
                                              Text('Lỗi tải hình ảnh', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 200,
                    maxHeight: 400,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Stack(
                    children: [
                      _imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _imageBytes!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error, size: 64, color: Colors.red),
                                      SizedBox(height: 8),
                                      Text('Lỗi tải hình ảnh', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : (widget.product != null && widget.product!.mainImage != null && widget.product!.mainImage!.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=${widget.product!.mainImage!}',
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) => const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.image, size: 64, color: Colors.grey),
                                          SizedBox(height: 8),
                                          Text('Lỗi tải hình ảnh', style: TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  height: 200,
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image, size: 64, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('Chưa có hình ảnh', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                      // Overlay để hiển thị icon zoom khi có hình ảnh
                      if (_imageBytes != null || 
                          (widget.product != null && widget.product!.mainImage != null && widget.product!.mainImage!.isNotEmpty))
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Image Selection Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Chọn từ thư viện'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Chụp ảnh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Nút xóa hình ảnh (chỉ hiển thị khi có hình ảnh)
              if ((_imageBytes != null) || 
                  (widget.product != null && widget.product!.mainImage != null && widget.product!.mainImage!.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                          _imageBytes = null;
                        });
                        // Nếu đang sửa sản phẩm, đánh dấu để xóa hình ảnh
                        if (widget.product != null) {
                          // Thêm logic để xóa hình ảnh khi lưu
                          _shouldRemoveImage = true;
                        }
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Xóa hình ảnh', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
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

