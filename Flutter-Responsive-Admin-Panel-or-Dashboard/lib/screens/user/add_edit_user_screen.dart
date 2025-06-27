import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddEditUserScreen extends StatefulWidget {
  final User? user;

  const AddEditUserScreen({super.key, this.user});

  @override
  State<AddEditUserScreen> createState() => _AddEditUserScreenState();
}

class _AddEditUserScreenState extends State<AddEditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController idController;
  late TextEditingController usernameController;
  late TextEditingController passwordController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController dobController;
  String selectedRole = 'user';
  String selectedGender = 'male';

  @override
  void initState() {
    super.initState();
    idController = TextEditingController(text: widget.user?.id.toString() ?? '');
    usernameController = TextEditingController(text: widget.user?.username ?? '');
    passwordController = TextEditingController(text: widget.user?.password ?? '');
    phoneController = TextEditingController(text: widget.user?.phone ?? '');
    emailController = TextEditingController(text: widget.user?.email ?? '');
    dobController = TextEditingController(text: widget.user?.dob ?? '');
    selectedRole = widget.user?.role ?? 'user';
    selectedGender = widget.user?.gender ?? 'male';
  }

  @override
  void dispose() {
    idController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    emailController.dispose();
    dobController.dispose();
    super.dispose();
  }

  void _saveUser() async {
    if (_formKey.currentState!.validate()) {
      final newUser = User(
        id: int.tryParse(idController.text) ?? 0,
        username: usernameController.text,
        password: passwordController.text.isNotEmpty ? passwordController.text : null,
        phone: phoneController.text,
        email: emailController.text,
        gender: selectedGender,
        role: selectedRole,
        createdAt: widget.user?.createdAt ?? '',
        updatedAt: widget.user?.updatedAt ?? '',
        dob: dobController.text,
      );
      String url;
      String method;
      Map<String, dynamic> body;
      if (widget.user == null) {
        url = 'http://127.0.0.1/EcommerceClothingApp/API/users/add_user.php';
        method = 'POST';
        body = {
          'username': newUser.username,
          'password': newUser.password,
          'phone': newUser.phone,
          'email': newUser.email,
          'gender': newUser.gender,
          'role': newUser.role,
          'dob': newUser.dob,
        };
      } else {
        url = 'http://127.0.0.1/EcommerceClothingApp/API/users/update_user.php';
        method = 'POST';
        body = {
          'id': newUser.id.toString(),
          'username': newUser.username,
          'phone': newUser.phone,
          'email': newUser.email,
          'gender': newUser.gender,
          'role': newUser.role,
          'dob': newUser.dob,
        };
        if (newUser.password != null && newUser.password!.isNotEmpty) {
          body['password'] = newUser.password;
        }
      }
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );
        final data = json.decode(response.body);
        if (data['success'] == true) {
          Navigator.pop(context, newUser);
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

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        validator: (value) => value!.isEmpty ? "Không được để trống" : null,
        readOnly: readOnly,
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: selectedRole,
        decoration: const InputDecoration(labelText: 'Vai trò'),
        items: const [
          DropdownMenuItem(value: 'user', child: Text('user')),
          DropdownMenuItem(value: 'admin', child: Text('admin')),
        ],
        onChanged: (value) {
          setState(() {
            selectedRole = value!;
          });
        },
        validator: (value) => value == null ? "Vui lòng chọn vai trò" : null,
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: selectedGender,
        decoration: const InputDecoration(labelText: 'Giới tính'),
        items: const [
          DropdownMenuItem(value: 'male', child: Text('male')),
          DropdownMenuItem(value: 'female', child: Text('female')),
        ],
        onChanged: (value) {
          setState(() {
            selectedGender = value!;
          });
        },
        validator: (value) => value == null ? "Vui lòng chọn giới tính" : null,
      ),
    );
  }

  Widget _buildDobField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: dobController,
        readOnly: true,
        decoration: const InputDecoration(labelText: 'Ngày sinh'),
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: dobController.text.isNotEmpty
                ? DateTime.tryParse(dobController.text) ?? DateTime.now()
                : DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            dobController.text = picked.toIso8601String().split('T').first;
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user == null ? "Thêm người dùng" : "Sửa người dùng"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (widget.user != null)
                _buildTextField(idController, "ID", isNumber: true, readOnly: true),
              _buildTextField(usernameController, "Tên đăng nhập"),
              _buildTextField(passwordController, "Mật khẩu"),
              _buildTextField(phoneController, "Số điện thoại"),
              _buildTextField(emailController, "Email"),
              _buildGenderDropdown(),
              _buildRoleDropdown(),
              _buildDobField(),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _saveUser, child: const Text("Lưu")),
            ],
          ),
        ),
      ),
    );
  }
}
