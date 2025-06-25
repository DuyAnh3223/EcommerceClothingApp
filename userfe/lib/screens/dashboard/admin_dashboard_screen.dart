import 'package:flutter/material.dart';
import 'package:userfe/services/auth_service.dart';
import 'package:userfe/screens/auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminDashboardScreen({Key? key, required this.user}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardHome(),
    const ProductsManagement(),
    const OrdersManagement(),
    const UsersManagement(),
  ];

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.grey.shade100,
            child: Column(
              children: [
                // User info
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.orange.shade700,
                        child: Text(
                          widget.user['Ten']?.substring(0, 1).toUpperCase() ?? 'A',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.user['Ten'] ?? 'Admin',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.user['Email'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Navigation menu
                Expanded(
                  child: ListView(
                    children: [
                      _buildMenuItem(0, Icons.dashboard, 'Dashboard'),
                      _buildMenuItem(1, Icons.inventory, 'Quản lý sản phẩm'),
                      _buildMenuItem(2, Icons.shopping_cart, 'Quản lý đơn hàng'),
                      _buildMenuItem(3, Icons.people, 'Quản lý người dùng'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
    return ListTile(
      leading: Icon(
        icon,
        color: _selectedIndex == index ? Colors.orange.shade700 : Colors.grey.shade600,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _selectedIndex == index ? Colors.orange.shade700 : Colors.grey.shade800,
          fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatCard('Tổng sản phẩm', '150', Icons.inventory, Colors.blue),
              const SizedBox(width: 16),
              _buildStatCard('Đơn hàng mới', '25', Icons.shopping_cart, Colors.green),
              const SizedBox(width: 16),
              _buildStatCard('Người dùng', '1,250', Icons.people, Colors.orange),
              const SizedBox(width: 16),
              _buildStatCard('Doanh thu', '15.5M', Icons.attach_money, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductsManagement extends StatelessWidget {
  const ProductsManagement({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quản lý sản phẩm',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Text('Chức năng quản lý sản phẩm sẽ được thêm vào đây'),
        ],
      ),
    );
  }
}

class OrdersManagement extends StatelessWidget {
  const OrdersManagement({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quản lý đơn hàng',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Text('Chức năng quản lý đơn hàng sẽ được thêm vào đây'),
        ],
      ),
    );
  }
}

class UsersManagement extends StatelessWidget {
  const UsersManagement({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quản lý người dùng',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Text('Chức năng quản lý người dùng sẽ được thêm vào đây'),
        ],
      ),
    );
  }
} 