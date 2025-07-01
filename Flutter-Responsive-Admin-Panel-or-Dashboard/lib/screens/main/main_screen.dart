import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/menu_app_controller.dart';
import '../../responsive.dart';
import '../dashboard/dashboard_screen.dart';
import '../products/product_screen.dart';
import '../user/user_screen.dart'; // thêm dòng này
import '../order/order_screen.dart'; // thêm dòng này
import '../payment/payment_dashboard_screen.dart'; // thêm dòng này
import '../products/attribute_manager_screen.dart';
import '../notifications/notification_management_screen.dart';
import '../user/all_user_addresses_screen.dart';
import '../product_review/product_review_screen.dart';
import '../product_combinations/product_combinations_screen.dart';

import 'components/side_menu.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Widget _selectedScreen = DashboardScreen();

  void _onMenuSelected(String menu) {
    setState(() {
      switch (menu) {
        case "Bảng điều khiển":
          _selectedScreen = DashboardScreen();
          break;
        case "Sản phẩm":
          _selectedScreen = const ProductScreen();
          break;
        case "Tổ hợp sản phẩm":
          _selectedScreen = const ProductCombinationsScreen();
          break;
        case "Người dùng":
          _selectedScreen = const UserScreen();
          break;
        case "Đơn hàng":
          _selectedScreen = const OrderScreen();
          break;
        case "Thông báo":
          _selectedScreen = const NotificationManagementScreen();
          break;
        // case "Chi tiết đơn hàng":
        //   _selectedScreen = const Center(child: Text("Trang 'Chi tiết đơn hàng' đang cập nhật"));
        //   break;
        case "Kiểm duyệt sản phẩm":
          _selectedScreen = const ProductReviewScreen();
          break;
        case "Thanh toán":
          _selectedScreen = const PaymentDashboardScreen();
          break;
        case "Quản lý thuộc tính":
          _selectedScreen = const AttributeManagerScreen();
          break;
        default:
          _selectedScreen = Center(child: Text("Trang '$menu' đang cập nhật"));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: context.read<MenuAppController>().scaffoldKey,
      drawer: SideMenu(onMenuSelected: _onMenuSelected),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Responsive.isDesktop(context))
              Expanded(
                child: SideMenu(onMenuSelected: _onMenuSelected),
              ),
            Expanded(
              flex: 5,
              child: _selectedScreen,
            ),
          ],
        ),
      ),
    );
  }
}
