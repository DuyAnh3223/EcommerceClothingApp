import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../products/product_screen.dart';

class SideMenu extends StatelessWidget {
  final Function(String)? onMenuSelected;

  const SideMenu({Key? key, this.onMenuSelected}) : super(key: key);

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Image.asset("assets/images/logo.png"),
          ),
          DrawerListTile(
            title: "Bảng điều khiển",
            svgSrc: "assets/icons/bangdieukhien.svg",
            press: () {
              if (onMenuSelected != null) {
                onMenuSelected!("Bảng điều khiển");
              }
            },
          ),
          DrawerListTile(
            title: "Sản phẩm",
            svgSrc: "assets/icons/sanpham.svg",
            press: () {
              if (onMenuSelected != null) {
                onMenuSelected!("Sản phẩm");
              }
            },
          ),
          DrawerListTile(
            title: "Tổ hợp sản phẩm",
            svgSrc: "assets/icons/widgets.svg",
            press: () {
              if (onMenuSelected != null) {
                onMenuSelected!("Tổ hợp sản phẩm");
              }
            },
          ),
          DrawerListTile(
            title: "Đơn hàng",
            svgSrc: "assets/icons/donhang.svg",
            press: () {
              if (onMenuSelected != null) {
                onMenuSelected!("Đơn hàng");
              }
            },
          ),
          DrawerListTile(
            title: "Thông báo",
            svgSrc: "assets/icons/thongbao.svg",
            press: () {
              if (onMenuSelected != null) {
                onMenuSelected!("Thông báo");
              }
            },
          ),
          DrawerListTile(
            title: "Người dùng",
            svgSrc: "assets/icons/nguoidung.svg",
            press: () {
              if (onMenuSelected != null) {
                onMenuSelected!("Người dùng");
              }
            },
          ),
          DrawerListTile(
            title: "Kiểm duyệt sản phẩm",
            svgSrc: "assets/icons/danhgia.svg",
            press: () {
              if (onMenuSelected != null) {
                onMenuSelected!("Kiểm duyệt sản phẩm");
              }
            },
          ),
          DrawerListTile(
            title: "Thanh toán",
            svgSrc: "assets/icons/thanhtoan.svg",
            press: () {
              if (onMenuSelected != null) {
                onMenuSelected!("Thanh toán");
              }
            },
          ),
          DrawerListTile(
            title: "Quản lý thuộc tính",
            svgSrc: "assets/icons/caidat.svg",
            press: () {
              if (onMenuSelected != null) {
                onMenuSelected!("Quản lý thuộc tính");
              }
            },
          ),
          DrawerListTile(
            title: "Quản lý rút tiền",
            svgSrc:
                "assets/icons/widgets.svg", // hoặc chọn icon phù hợp hơn nếu có
            press: () {
              if (onMenuSelected != null) {
                onMenuSelected!("Quản lý rút tiền");
              }
            },
          ),
          DrawerListTile(
            title: "Quản lý Gói BACoin",
            svgSrc:
                "assets/icons/widgets.svg", // hoặc chọn icon phù hợp hơn nếu có
            press: () {
              if (onMenuSelected != null) {
                onMenuSelected!("Quản lý Gói BACoin");
              }
            },
          ),
          DrawerListTile(
            title: "Quản lý Vouchers",
            svgSrc:
                "assets/icons/widgets.svg", // hoặc chọn icon phù hợp hơn nếu có
            press: () {
              if (onMenuSelected != null) {
                onMenuSelected!("Quản lý Vouchers");
              }
            },
          ),
          const Divider(color: Colors.white54),
          DrawerListTile(
            title: "Đăng xuất",
            svgSrc: "assets/icons/dangxuat.svg",
            press: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

class DrawerListTile extends StatelessWidget {
  const DrawerListTile({
    Key? key,
    // For selecting those three line once press "Command+D"
    required this.title,
    required this.svgSrc,
    required this.press,
  }) : super(key: key);

  final String title, svgSrc;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: press,
      horizontalTitleGap: 0.0,
      leading: SvgPicture.asset(
        svgSrc,
        colorFilter: ColorFilter.mode(Colors.white54, BlendMode.srcIn),
        height: 16,
      ),
      title: Text(
        title,
        style: TextStyle(color: Colors.white54),
      ),
    );
  }
}
