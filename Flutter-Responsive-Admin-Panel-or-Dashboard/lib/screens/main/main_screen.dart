// import 'package:admin/controllers/menu_app_controller.dart';
// import 'package:admin/responsive.dart';
// import 'package:admin/screens/dashboard/dashboard_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import 'components/side_menu.dart';

// class MainScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: context.read<MenuAppController>().scaffoldKey,
//       drawer: SideMenu(),
//       body: SafeArea(
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // We want this side menu only for large screen
//             if (Responsive.isDesktop(context))
//               Expanded(
//                 // default flex = 1
//                 // and it takes 1/6 part of the screen
//                 child: SideMenu(),
//               ),
//             Expanded(
//               // It takes 5/6 part of the screen
//               flex: 5,
//               child: DashboardScreen(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// =================Cái này chạy được Product =================
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../controllers/menu_app_controller.dart';
// import '../../responsive.dart';
// import '../dashboard/dashboard_screen.dart';
// import '../products/product_screen.dart';
// import 'components/side_menu.dart';

// class MainScreen extends StatefulWidget {
//   const MainScreen({super.key});

//   @override
//   State<MainScreen> createState() => _MainScreenState();
// }

// class _MainScreenState extends State<MainScreen> {
//   Widget _selectedScreen = DashboardScreen();

//   void _onMenuSelected(String menu) {
//     setState(() {
//       switch (menu) {
//         case "Sản phẩm":
//           _selectedScreen = const ProductScreen();
//           break;
//         case "Bảng điều khiển":
//           _selectedScreen = DashboardScreen();
//           break;
//         default:
//           _selectedScreen = Center(child: Text("Trang '$menu' đang cập nhật"));
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: context.read<MenuAppController>().scaffoldKey,
//       drawer: SideMenu(onMenuSelected: _onMenuSelected),
//       body: SafeArea(
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (Responsive.isDesktop(context))
//               Expanded(
//                 child: SideMenu(onMenuSelected: _onMenuSelected),
//               ),
//             Expanded(
//               flex: 5,
//               child: _selectedScreen,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/menu_app_controller.dart';
import '../../responsive.dart';
import '../dashboard/dashboard_screen.dart';
import '../products/product_screen.dart';
import '../user/user_screen.dart'; // thêm dòng này
import '../order/order_screen.dart'; // thêm dòng này
import '../products/attribute_manager_screen.dart';

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
        case "Người dùng":
          _selectedScreen = const UserScreen();
          break;
        case "Đơn hàng":
          _selectedScreen = const OrderScreen();
          break;
        case "Chi tiết đơn hàng":
          _selectedScreen = const Center(child: Text("Trang 'Chi tiết đơn hàng' đang cập nhật"));
          break;
        case "Đánh giá":
          _selectedScreen = const Center(child: Text("Trang 'Đánh giá' đang cập nhật"));
          break;
        case "Thanh toán":
          _selectedScreen = const Center(child: Text("Trang 'Thanh toán' đang cập nhật"));
          break;
        case "Địa chỉ":
          _selectedScreen = const Center(child: Text("Trang 'Địa chỉ' đang cập nhật"));
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
