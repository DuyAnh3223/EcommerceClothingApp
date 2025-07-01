import 'package:flutter/material.dart';
import '../../models/agency_product_model.dart';
import '../../services/agency_service.dart';
import '../../services/image_service.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class AddEditAgencyProductScreen extends StatefulWidget {
  final AgencyProduct? product;
  const AddEditAgencyProductScreen({Key? key, this.product}) : super(key: key);

  @override
  State<AddEditAgencyProductScreen> createState() => _AddEditAgencyProductScreenState();
}

class _AddEditAgencyProductScreenState extends State<AddEditAgencyProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _categoryController;
  late TextEditingController _genderController;
  late TextEditingController _imageController;
  bool isLoading = false;
  
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
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descController = TextEditingController(text: widget.product?.description ?? '');
    _categoryController = TextEditingController(text: widget.product?.category ?? 'T-Shirts');
    _genderController = TextEditingController(text: widget.product?.genderTarget ?? 'unisex');
    _imageController = TextEditingController(text: widget.product?.mainImage ?? '');
    
    selectedCategory = widget.product?.category ?? 'T-Shirts';
    selectedGenderTarget = widget.product?.genderTarget ?? 'unisex';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    _genderController.dispose();
    _imageController.dispose();
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

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Upload hình ảnh trước nếu có hình ảnh mới được chọn
    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage();
      if (imageUrl == null) {
        return; // Dừng nếu upload thất bại
      }
    }

    setState(() { isLoading = true; });
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    final category = selectedCategory;
    final gender = selectedGenderTarget;
    
    Map<String, dynamic> result;
    if (widget.product == null) {
      // Thêm mới
      result = await AgencyService.addProduct(
        name: name,
        description: desc,
        category: category,
        genderTarget: gender,
        mainImage: imageUrl,
      );
    } else {
      // Sửa
      result = await AgencyService.updateProduct(
        productId: widget.product!.id,
        name: name,
        description: desc,
        category: category,
        genderTarget: gender,
        mainImage: imageUrl,
      );
    }
    setState(() { isLoading = false; });
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lưu sản phẩm thành công'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Lỗi'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
                validator: (v) => v == null || v.isEmpty ? 'Nhập tên sản phẩm' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 2,
              ),
              // Danh mục dropdown
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Danh mục *',
                  border: OutlineInputBorder(),
                ),
                items: categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue!;
                  });
                },
                validator: (value) => value == null ? 'Vui lòng chọn danh mục' : null,
              ),
              const SizedBox(height: 16),
              
              // Đối tượng dropdown
              DropdownButtonFormField<String>(
                value: selectedGenderTarget,
                decoration: const InputDecoration(
                  labelText: 'Đối tượng *',
                  border: OutlineInputBorder(),
                ),
                items: genderTargets.map((String gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedGenderTarget = newValue!;
                  });
                },
                validator: (value) => value == null ? 'Vui lòng chọn đối tượng' : null,
              ),
              const SizedBox(height: 16),
              
              // Hình ảnh sản phẩm
              const Text(
                'Hình ảnh sản phẩm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              const SizedBox(height: 24),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveProduct,
                      child: Text(widget.product == null ? 'Thêm sản phẩm' : 'Lưu thay đổi'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
} 