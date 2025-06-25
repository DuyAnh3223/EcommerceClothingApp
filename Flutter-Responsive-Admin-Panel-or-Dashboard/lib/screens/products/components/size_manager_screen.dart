import 'package:flutter/material.dart';

class SizeManagerScreen extends StatefulWidget {
  const SizeManagerScreen({Key? key}) : super(key: key);

  @override
  State<SizeManagerScreen> createState() => _SizeManagerScreenState();
}

class _SizeManagerScreenState extends State<SizeManagerScreen> {
  List<String> sizes = ['S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
  final TextEditingController _controller = TextEditingController();
  int? editingIndex;

  void _addSize() {
    final size = _controller.text.trim();
    if (size.isNotEmpty && !sizes.contains(size)) {
      setState(() {
        sizes.add(size);
        _controller.clear();
      });
    }
  }

  void _editSize(int index) {
    setState(() {
      editingIndex = index;
      _controller.text = sizes[index];
    });
  }

  void _saveEdit() {
    final size = _controller.text.trim();
    if (size.isNotEmpty && editingIndex != null) {
      setState(() {
        sizes[editingIndex!] = size;
        editingIndex = null;
        _controller.clear();
      });
    }
  }

  void _deleteSize(int index) {
    setState(() {
      sizes.removeAt(index);
      if (editingIndex == index) {
        editingIndex = null;
        _controller.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý kích thước'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Tên size',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                editingIndex == null
                    ? ElevatedButton(
                        onPressed: _addSize,
                        child: const Text('Thêm'),
                      )
                    : ElevatedButton(
                        onPressed: _saveEdit,
                        child: const Text('Lưu'),
                      ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: sizes.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(sizes[index]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editSize(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteSize(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 