import 'package:flutter/material.dart';
import '../../services/agency_service.dart';

class AgencyAttributeManagerScreen extends StatefulWidget {
  const AgencyAttributeManagerScreen({Key? key}) : super(key: key);

  @override
  State<AgencyAttributeManagerScreen> createState() => _AgencyAttributeManagerScreenState();
}

class _AgencyAttributeManagerScreenState extends State<AgencyAttributeManagerScreen> {
  List<Map<String, dynamic>> attributes = [];
  int? selectedAttributeId;
  bool isLoading = false;
  final TextEditingController attrController = TextEditingController();
  final TextEditingController valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAttributes();
  }

  @override
  void dispose() {
    attrController.dispose();
    valueController.dispose();
    super.dispose();
  }

  Future<void> _loadAttributes() async {
    setState(() { isLoading = true; });
    try {
      final result = await AgencyService.getAttributes();
      if (result['success']) {
        setState(() {
          attributes = List<Map<String, dynamic>>.from(result['data']?['attributes'] ?? []);
          isLoading = false;
        });
      } else {
        setState(() { isLoading = false; });
        _showSnackBar(result['message'] ?? 'Lỗi khi tải thuộc tính', isError: true);
      }
    } catch (e) {
      setState(() { isLoading = false; });
      _showSnackBar('Lỗi kết nối: $e', isError: true);
    }
  }

  Future<void> _addAttribute() async {
    final name = attrController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Vui lòng nhập tên thuộc tính', isError: true);
      return;
    }

    setState(() { isLoading = true; });
    try {
      final result = await AgencyService.addAttribute(name);
      if (result['success']) {
        attrController.clear();
        await _loadAttributes();
        _showSnackBar('Thêm thuộc tính thành công');
      } else {
        setState(() { isLoading = false; });
        _showSnackBar(result['message'] ?? 'Lỗi khi thêm thuộc tính', isError: true);
      }
    } catch (e) {
      setState(() { isLoading = false; });
      _showSnackBar('Lỗi kết nối: $e', isError: true);
    }
  }

  Future<void> _deleteAttribute(int attributeId) async {
    // Hiển thị dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa thuộc tính này? Tất cả giá trị của thuộc tính sẽ bị xóa theo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() { isLoading = true; });
    try {
      final result = await AgencyService.deleteAttribute(attributeId);
      if (result['success']) {
        if (selectedAttributeId == attributeId) {
          selectedAttributeId = null;
        }
        await _loadAttributes();
        _showSnackBar('Xóa thuộc tính thành công');
      } else {
        setState(() { isLoading = false; });
        _showSnackBar(result['message'] ?? 'Lỗi khi xóa thuộc tính', isError: true);
      }
    } catch (e) {
      setState(() { isLoading = false; });
      _showSnackBar('Lỗi kết nối: $e', isError: true);
    }
  }

  Future<void> _addAttributeValue() async {
    if (selectedAttributeId == null) {
      _showSnackBar('Vui lòng chọn một thuộc tính', isError: true);
      return;
    }

    final value = valueController.text.trim();
    if (value.isEmpty) {
      _showSnackBar('Vui lòng nhập giá trị', isError: true);
      return;
    }

    setState(() { isLoading = true; });
    try {
      final result = await AgencyService.addAttributeValue(
        attributeId: selectedAttributeId!,
        value: value,
      );
      if (result['success']) {
        valueController.clear();
        await _loadAttributes();
        _showSnackBar('Thêm giá trị thành công');
      } else {
        setState(() { isLoading = false; });
        _showSnackBar(result['message'] ?? 'Lỗi khi thêm giá trị', isError: true);
      }
    } catch (e) {
      setState(() { isLoading = false; });
      _showSnackBar('Lỗi kết nối: $e', isError: true);
    }
  }

  Future<void> _deleteAttributeValue(int valueId) async {
    // Hiển thị dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa giá trị này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() { isLoading = true; });
    try {
      final result = await AgencyService.deleteAttributeValue(valueId);
      if (result['success']) {
        await _loadAttributes();
        _showSnackBar('Xóa giá trị thành công');
      } else {
        setState(() { isLoading = false; });
        _showSnackBar(result['message'] ?? 'Lỗi khi xóa giá trị', isError: true);
      }
    } catch (e) {
      setState(() { isLoading = false; });
      _showSnackBar('Lỗi kết nối: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thuộc tính & giá trị'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Danh sách thuộc tính
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Danh sách thuộc tính', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: attrController,
                                decoration: const InputDecoration(
                                  labelText: 'Tên thuộc tính',
                                  border: OutlineInputBorder(),
                                  hintText: 'Ví dụ: Màu sắc, Kích thước...',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addAttribute,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Thêm'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: attributes.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Chưa có thuộc tính nào. Hãy thêm thuộc tính đầu tiên!',
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: attributes.length,
                                  itemBuilder: (context, index) {
                                    final attr = attributes[index];
                                    final values = List<Map<String, dynamic>>.from(attr['values'] ?? []);
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        title: Text(
                                          attr['name'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text('${values.length} giá trị'),
                                        selected: selectedAttributeId == (attr['id'] ?? 0),
                                        trailing: (attr['created_by_name'] == 'agency') ? IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteAttribute(attr['id'] ?? 0),
                                          tooltip: 'Xóa thuộc tính',
                                        ) : null,
                                        onTap: () {
                                          setState(() {
                                            selectedAttributeId = attr['id'] ?? 0;
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Danh sách giá trị thuộc tính
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: selectedAttributeId == null
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_forward, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Chọn một thuộc tính để xem/điều chỉnh giá trị',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Giá trị thuộc tính: ${attributes.firstWhere((attr) => (attr['id'] ?? 0) == selectedAttributeId, orElse: () => {'name': 'Unknown'})['name'] ?? 'Unknown'}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: valueController,
                                      decoration: const InputDecoration(
                                        labelText: 'Giá trị',
                                        border: OutlineInputBorder(),
                                        hintText: 'Nhập giá trị mới...',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _addAttributeValue,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Thêm'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Expanded(
                                child: Builder(
                                  builder: (context) {
                                    final selectedAttr = attributes.firstWhere(
                                      (attr) => (attr['id'] ?? 0) == selectedAttributeId,
                                      orElse: () => {'values': []},
                                    );
                                    final values = List<Map<String, dynamic>>.from(selectedAttr['values'] ?? []);
                                    
                                    return values.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'Chưa có giá trị nào cho thuộc tính này',
                                              style: TextStyle(fontSize: 16, color: Colors.grey),
                                            ),
                                          )
                                        : ListView.builder(
                                            itemCount: values.length,
                                            itemBuilder: (context, index) {
                                              final val = values[index];
                                              return Card(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                child: ListTile(
                                                  title: Text(val['value'] ?? ''),
                                                  trailing: (val['created_by_name'] == 'agency') ? IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                    onPressed: () => _deleteAttributeValue(val['id'] ?? 0),
                                                    tooltip: 'Xóa giá trị',
                                                  ) : null,
                                                ),
                                              );
                                            },
                                          );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
    );
  }
} 