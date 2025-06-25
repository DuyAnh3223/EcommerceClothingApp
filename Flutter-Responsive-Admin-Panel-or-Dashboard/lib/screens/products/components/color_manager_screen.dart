import 'package:flutter/material.dart';

class ColorManagerScreen extends StatefulWidget {
  const ColorManagerScreen({Key? key}) : super(key: key);

  @override
  State<ColorManagerScreen> createState() => _ColorManagerScreenState();
}

class _ColorManagerScreenState extends State<ColorManagerScreen> {
  List<String> colors = ['white', 'black', 'red', 'blue', 'green', 'yellow'];
  final TextEditingController _controller = TextEditingController();
  int? editingIndex;

  void _addColor() {
    final color = _controller.text.trim();
    if (color.isNotEmpty && !colors.contains(color)) {
      setState(() {
        colors.add(color);
        _controller.clear();
      });
    }
  }

  void _editColor(int index) {
    setState(() {
      editingIndex = index;
      _controller.text = colors[index];
    });
  }

  void _saveEdit() {
    final color = _controller.text.trim();
    if (color.isNotEmpty && editingIndex != null) {
      setState(() {
        colors[editingIndex!] = color;
        editingIndex = null;
        _controller.clear();
      });
    }
  }

  void _deleteColor(int index) {
    setState(() {
      colors.removeAt(index);
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
        title: const Text('Quản lý màu sắc'),
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
                      labelText: 'Tên màu',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                editingIndex == null
                    ? ElevatedButton(
                        onPressed: _addColor,
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
                itemCount: colors.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(colors[index]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editColor(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteColor(index),
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