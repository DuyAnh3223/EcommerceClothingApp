-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Máy chủ: 127.0.0.1
-- Thời gian đã tạo: Th7 05, 2025 lúc 01:35 PM
-- Phiên bản máy phục vụ: 10.4.32-MariaDB
-- Phiên bản PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Cơ sở dữ liệu: `clothing_appstore`
--

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `attributes`
--

CREATE TABLE `attributes` (
  `id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `created_by` int(11) DEFAULT NULL COMMENT 'user_id who created this attribute',
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `attributes`
--

INSERT INTO `attributes` (`id`, `name`, `created_by`, `created_at`) VALUES
(1, 'color', 6, '2025-06-27 10:35:00'),
(2, 'size', 6, '2025-06-27 10:35:00'),
(3, 'brand', 6, '2025-06-27 10:35:00'),
(22, 'style', 9, '2025-07-01 08:16:41');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `attribute_values`
--

CREATE TABLE `attribute_values` (
  `id` int(11) NOT NULL,
  `attribute_id` int(11) NOT NULL,
  `value` varchar(50) NOT NULL,
  `created_by` int(11) DEFAULT NULL COMMENT 'user_id who created this attribute value'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `attribute_values`
--

INSERT INTO `attribute_values` (`id`, `attribute_id`, `value`, `created_by`) VALUES
(12, 2, 'X', 6),
(13, 2, 'XL', 6),
(14, 3, 'Nike', 6),
(15, 3, 'Adidas', 6),
(16, 1, 'black', 6),
(17, 1, 'while', 6),
(18, 1, 'yellow', 6),
(30, 22, 'fit', 9),
(31, 22, 'big', 9),
(32, 22, 'fashion', 9);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `bacoin_packages`
--

CREATE TABLE `bacoin_packages` (
  `id` int(11) NOT NULL,
  `package_name` varchar(100) NOT NULL,
  `price_vnd` decimal(15,2) NOT NULL,
  `bacoin_amount` decimal(15,2) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `bacoin_packages`
--

INSERT INTO `bacoin_packages` (`id`, `package_name`, `price_vnd`, `bacoin_amount`, `description`) VALUES
(1, 'Gói 50K Updated Directge', 55000432.00, 65000432.00, 'Gói 50K đã được cập nhật trực tiếprth'),
(2, 'Gói 100K', 100000.00, 115000.00, 'Gói nạp BACoin trị giá 100.000 VNĐ'),
(3, 'Gói 300K', 300000.00, 380000.00, 'Gói nạp BACoin trị giá 300.000 VNĐ'),
(4, 'Gói 500K', 500000.00, 620000.00, 'Gói nạp BACoin trị giá 500.000 VNĐ'),
(5, 'Gói 1 triệu', 1000000.00, 1300000.00, 'Gói nạp BACoin trị giá 1.000.000 VNĐ'),
(9, 'rưe', 4.00, 43.00, 'ew');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `bacoin_transactions`
--

CREATE TABLE `bacoin_transactions` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `type` enum('deposit','spend','refund','withdraw') NOT NULL,
  `description` text DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `bacoin_transactions`
--

INSERT INTO `bacoin_transactions` (`id`, `user_id`, `amount`, `type`, `description`, `created_at`) VALUES
(1, 4, 115000.00, 'deposit', 'Mua gói BACoin #2', '2025-07-04 00:30:01'),
(2, 4, 1300000.00, 'deposit', 'Mua gói BACoin #5', '2025-07-04 00:30:26'),
(3, 4, 115000.00, 'deposit', 'Mua gói BACoin #2', '2025-07-04 01:05:20'),
(4, 4, 115000.00, 'deposit', 'Mua gói BACoin #2', '2025-07-04 01:05:30'),
(5, 4, 115000.00, 'deposit', 'Mua gói BACoin #2', '2025-07-04 01:36:37'),
(6, 4, 380000.00, 'deposit', 'Mua gói BACoin #3', '2025-07-04 01:36:37'),
(7, 9, 55000.00, 'deposit', 'Mua gói BACoin #1', '2025-07-04 09:29:22'),
(8, 4, 55000.00, 'deposit', 'Mua gói BACoin #1', '2025-07-04 09:34:58'),
(9, 4, 200000.00, 'spend', 'Thanh toán đơn hàng #123', '2025-07-04 10:49:59'),
(10, 4, 200000.00, 'spend', 'Thanh toán đơn hàng #125', '2025-07-04 11:01:42'),
(11, 4, 200000.00, 'spend', 'Thanh toán đơn hàng #126', '2025-07-04 11:05:39'),
(12, 9, 55000.00, 'deposit', 'Mua gói BACoin #1', '2025-07-04 11:09:27'),
(13, 4, 116666.00, 'spend', 'Thanh toán đơn hàng #128', '2025-07-04 12:17:28'),
(14, 4, 390000.00, 'spend', 'Thanh toán đơn hàng #129', '2025-07-04 12:28:25'),
(15, 4, 240000.00, 'spend', 'Thanh toán đơn hàng #130', '2025-07-04 13:22:30'),
(16, 4, 66666.00, 'spend', 'Thanh toán đơn hàng #133', '2025-07-04 17:42:14'),
(17, 4, 110000.00, 'spend', 'Thanh toán đơn hàng #134', '2025-07-04 18:41:32'),
(18, 4, 1300000.00, 'deposit', 'Mua gói BACoin #5', '2025-07-04 18:41:43'),
(19, 4, 120000.00, 'spend', 'Thanh toán đơn hàng #138', '2025-07-04 20:50:34'),
(20, 4, 1300000.00, 'deposit', 'Mua gói BACoin #5', '2025-07-04 20:50:42'),
(21, 4, 60000.00, 'spend', 'Thanh toán đơn hàng #141', '2025-07-05 11:09:44'),
(22, 4, 115000.00, 'deposit', 'Mua gói BACoin #2', '2025-07-05 11:11:00'),
(37, 4, 60000.00, 'spend', 'Thanh toán đơn hàng #155', '2025-07-05 12:13:46'),
(38, 9, 50000.00, '', 'Nhận thanh toán đơn hàng #155 (giá gốc)', '2025-07-05 12:13:46'),
(39, 6, 10000.00, '', 'Nhận thanh toán đơn hàng #155', '2025-07-05 12:13:46'),
(40, 4, 60000.00, 'spend', 'Thanh toán đơn hàng #156', '2025-07-05 12:15:16'),
(41, 9, 50000.00, '', 'Nhận thanh toán đơn hàng #156 (giá gốc)', '2025-07-05 12:15:16'),
(42, 6, 10000.00, '', 'Nhận thanh toán đơn hàng #156', '2025-07-05 12:15:16'),
(43, 4, 60000.00, 'spend', 'Thanh toán đơn hàng #157', '2025-07-05 12:19:31'),
(44, 9, 50000.00, '', 'Nhận thanh toán đơn hàng #157 (giá gốc)', '2025-07-05 12:19:31'),
(45, 6, 10000.00, '', 'Nhận thanh toán đơn hàng #157', '2025-07-05 12:19:31'),
(46, 4, 60000.00, 'spend', 'Thanh toán đơn hàng #159', '2025-07-05 12:23:19'),
(47, 9, 50000.00, '', 'Nhận thanh toán đơn hàng #159 (giá gốc)', '2025-07-05 12:23:19'),
(48, 6, 10000.00, '', 'Nhận thanh toán đơn hàng #159', '2025-07-05 12:23:19'),
(49, 4, 60000.00, 'spend', 'Thanh toán đơn hàng #160', '2025-07-05 12:40:03'),
(50, 9, 50000.00, '', 'Nhận thanh toán đơn hàng #160 (giá gốc)', '2025-07-05 12:40:03'),
(51, 6, 10000.00, '', 'Nhận thanh toán đơn hàng #160', '2025-07-05 12:40:03'),
(52, 4, 60000.00, 'spend', 'Thanh toán đơn hàng #161', '2025-07-05 12:47:07'),
(53, 9, 50000.00, '', 'Nhận thanh toán đơn hàng #161 (giá gốc)', '2025-07-05 12:47:07'),
(54, 6, 10000.00, '', 'Nhận thanh toán đơn hàng #161', '2025-07-05 12:47:07'),
(55, 4, 43.00, 'deposit', 'Mua gói BACoin #9', '2025-07-05 14:11:59'),
(56, 4, 200000.00, 'spend', 'Thanh toán đơn hàng #167', '2025-07-05 17:58:58'),
(57, 6, 200000.00, '', 'Nhận thanh toán đơn hàng #167', '2025-07-05 17:58:58');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `cart_items`
--

CREATE TABLE `cart_items` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `product_id` int(11) DEFAULT NULL,
  `variant_id` int(11) DEFAULT NULL,
  `quantity` int(11) NOT NULL DEFAULT 1,
  `added_at` datetime DEFAULT current_timestamp(),
  `combination_id` int(11) DEFAULT NULL COMMENT 'ID của combo (nếu là combo)',
  `combination_name` varchar(255) DEFAULT NULL COMMENT 'Tên combo',
  `combination_image` varchar(255) DEFAULT NULL COMMENT 'Hình ảnh combo',
  `combination_price` decimal(15,2) DEFAULT NULL COMMENT 'Giá combo',
  `combination_items` text DEFAULT NULL COMMENT 'JSON chứa thông tin các sản phẩm trong combo'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `cart_items`
--

INSERT INTO `cart_items` (`id`, `user_id`, `product_id`, `variant_id`, `quantity`, `added_at`, `combination_id`, `combination_name`, `combination_image`, `combination_price`, `combination_items`) VALUES
(94, 9, NULL, NULL, 1, '2025-07-03 14:48:45', 11, '', NULL, 95677.00, '[{\"product_id\":30,\"variant_id\":29,\"quantity\":1},{\"product_id\":31,\"variant_id\":27,\"quantity\":1}]'),
(152, 4, 26, 23, 1, '2025-07-05 18:34:23', NULL, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `notifications`
--

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `content` text DEFAULT NULL,
  `type` enum('order_status','sale','voucher','other','product_approval') DEFAULT 'other',
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `notifications`
--

INSERT INTO `notifications` (`id`, `user_id`, `title`, `content`, `type`, `is_read`, `created_at`) VALUES
(77, 9, 'Sản phẩm bị từ chối', 'Sản phẩm \'Quần da bò\' đã bị admin từ chối. Lý do: Tồn kho không hợp lệ', 'product_approval', 0, '2025-07-01 12:03:06'),
(78, 4, 'Cập nhật trạng thái đơn hàng', 'Đơn hàng #107 đã được cập nhật trạng thái thành: pending', 'order_status', 1, '2025-07-03 09:49:46'),
(79, 6, 'Sản phẩm mới cần duyệt', 'Sản phẩm \'Quần lửng\' từ agency cần được duyệt.', 'product_approval', 0, '2025-07-03 13:25:25'),
(80, 6, 'Sản phẩm mới cần duyệt', 'Sản phẩm \'Quần tây\' từ agency cần được duyệt.', 'product_approval', 0, '2025-07-03 13:25:27'),
(81, 6, 'Sản phẩm mới cần duyệt', 'Sản phẩm \'Áo khoác Vải nỉ\' từ agency cần được duyệt.', 'product_approval', 0, '2025-07-03 13:25:28'),
(82, 6, 'Sản phẩm mới cần duyệt', 'Sản phẩm \'Áo thun co giãn\' từ agency cần được duyệt.', 'product_approval', 0, '2025-07-03 13:25:29'),
(83, 9, 'Sản phẩm đã được duyệt', 'Sản phẩm \'Quần lửng\' đã được admin duyệt và sẽ được hiển thị trên cửa hàng.', 'product_approval', 0, '2025-07-03 13:25:39'),
(84, 9, 'Sản phẩm đã được duyệt', 'Sản phẩm \'Quần tây\' đã được admin duyệt và sẽ được hiển thị trên cửa hàng.', 'product_approval', 0, '2025-07-03 13:25:40'),
(85, 9, 'Sản phẩm đã được duyệt', 'Sản phẩm \'Áo khoác Vải nỉ\' đã được admin duyệt và sẽ được hiển thị trên cửa hàng.', 'product_approval', 1, '2025-07-03 13:25:42'),
(86, 9, 'Sản phẩm đã được duyệt', 'Sản phẩm \'Áo thun co giãn\' đã được admin duyệt và sẽ được hiển thị trên cửa hàng.', 'product_approval', 1, '2025-07-03 13:25:43'),
(87, 6, 'Tổ hợp sản phẩm mới cần duyệt', 'Tổ hợp sản phẩm \'Bảo gà\' từ agency cần được duyệt.', '', 0, '2025-07-03 14:29:43'),
(88, 6, 'Tổ hợp sản phẩm mới cần duyệt', 'Tổ hợp sản phẩm \'AgencyTest\' từ agency cần được duyệt.', '', 0, '2025-07-03 14:50:41'),
(89, 6, 'Tổ hợp sản phẩm mới cần duyệt', 'Tổ hợp sản phẩm \'\' từ agency cần được duyệt.', '', 0, '2025-07-03 14:51:21'),
(90, 6, 'Tổ hợp sản phẩm mới cần duyệt', 'Tổ hợp sản phẩm \'opt1\' từ agency cần được duyệt.', '', 0, '2025-07-03 14:54:49'),
(91, 4, 'Cập nhật trạng thái đơn hàng', 'Đơn hàng #111 đã được cập nhật trạng thái thành: pending', 'order_status', 1, '2025-07-04 09:00:18'),
(92, 6, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Áo đi biển | Số lượng: 1', 'order_status', 0, '2025-07-04 09:01:23'),
(93, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #111 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 200,000 VNĐ', 'order_status', 1, '2025-07-04 09:01:23'),
(94, 6, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Áo đi biển | Số lượng: 1', 'order_status', 0, '2025-07-04 09:37:02'),
(95, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #114 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 200,000 VNĐ', 'order_status', 1, '2025-07-04 09:37:02'),
(96, 6, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Áo khoác | Số lượng: 1', 'order_status', 0, '2025-07-04 09:46:14'),
(97, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #115 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 320,000 VNĐ', 'order_status', 1, '2025-07-04 09:46:14'),
(98, 6, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Áo khoác | Số lượng: 1', 'order_status', 0, '2025-07-04 09:54:14'),
(99, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #116 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 320,000 VNĐ', 'order_status', 1, '2025-07-04 09:54:14'),
(100, 6, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Áo khoác | Số lượng: 1', 'order_status', 0, '2025-07-04 10:15:14'),
(101, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #119 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 320,000 VNĐ', 'order_status', 1, '2025-07-04 10:15:14'),
(102, 6, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Áo khoác | Số lượng: 1', 'order_status', 0, '2025-07-04 10:40:42'),
(103, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #118 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 320,000 VNĐ', 'order_status', 1, '2025-07-04 10:40:42'),
(104, 6, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Áo sơ mi tay ngắn | Số lượng: 1', 'order_status', 0, '2025-07-04 10:46:35'),
(105, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #122 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 50,000 VNĐ', 'order_status', 1, '2025-07-04 10:46:35'),
(106, 6, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Áo đi biển | Số lượng: 1', 'order_status', 0, '2025-07-04 10:51:26'),
(107, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #123 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 200,000 VNĐ', 'order_status', 1, '2025-07-04 10:51:26'),
(108, 6, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Áo khoác | Số lượng: 1', 'order_status', 0, '2025-07-04 10:53:16'),
(109, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #124 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 320,000 VNĐ', 'order_status', 1, '2025-07-04 10:53:16'),
(110, 9, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Quần lửng | Số lượng: 1', 'order_status', 1, '2025-07-04 12:30:11'),
(111, 6, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Áo đi biển | Số lượng: 2', 'order_status', 0, '2025-07-04 12:30:11'),
(112, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #127 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 460,000 VNĐ <=> BACoin', 'order_status', 1, '2025-07-04 12:30:11'),
(113, 9, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Quần tây | Số lượng: 1', 'order_status', 1, '2025-07-04 13:26:55'),
(114, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #131 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 54,812 VNĐ <=> BACoin', 'order_status', 1, '2025-07-04 13:26:55'),
(115, 9, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Quần lửng | Số lượng: 1', 'order_status', 1, '2025-07-04 18:53:00'),
(116, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #135 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 60,000 VNĐ <=> BACoin', 'order_status', 1, '2025-07-04 18:53:00'),
(117, 6, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Áo đi biển | Số lượng: 1', 'order_status', 0, '2025-07-04 20:27:08'),
(118, 9, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Quần lửng | Số lượng: 1', 'order_status', 1, '2025-07-04 20:27:08'),
(119, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #136 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 260,000 VNĐ <=> BACoin', 'order_status', 1, '2025-07-04 20:27:08'),
(120, 6, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Áo đi biển | Số lượng: 1', 'order_status', 0, '2025-07-04 20:51:05'),
(121, 9, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Quần lửng | Số lượng: 2', 'order_status', 1, '2025-07-04 20:51:05'),
(122, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #137 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 320,000 VNĐ <=> BACoin', 'order_status', 1, '2025-07-04 20:51:05'),
(123, 9, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Quần lửng | Số lượng: 2', 'order_status', 1, '2025-07-04 20:54:42'),
(124, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #139 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 120,000 VNĐ <=> BACoin', 'order_status', 1, '2025-07-04 20:54:42'),
(125, 6, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Áo khoác | Số lượng: 1', 'order_status', 0, '2025-07-05 11:03:11'),
(126, 9, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Quần lửng | Số lượng: 1', 'order_status', 0, '2025-07-05 11:03:11'),
(127, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #140 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 380,000 VNĐ <=> BACoin', 'order_status', 1, '2025-07-05 11:03:11'),
(128, 9, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Quần lửng | Số lượng: 1', 'order_status', 0, '2025-07-05 12:27:20'),
(129, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #158 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 60,000 VNĐ <=> BACoin', 'order_status', 1, '2025-07-05 12:27:20'),
(130, 9, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Quần lửng | Số lượng: 1', 'order_status', 0, '2025-07-05 12:49:30'),
(131, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #162 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 60,000 VNĐ <=> BACoin', 'order_status', 1, '2025-07-05 12:49:30'),
(132, 6, 'Sản phẩm của bạn đã được bán', 'Sản phẩm: Áo sơ mi tay dài | Số lượng: 1', 'order_status', 0, '2025-07-05 18:33:12'),
(133, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #169 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 70,000 VNĐ <=> BACoin', 'order_status', 1, '2025-07-05 18:33:12');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `orders`
--

CREATE TABLE `orders` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `address_id` int(11) NOT NULL,
  `order_date` datetime DEFAULT current_timestamp(),
  `total_amount` decimal(15,2) NOT NULL,
  `platform_fee` decimal(15,2) DEFAULT 0.00 COMMENT 'Platform fee for agency products',
  `status` enum('pending','confirmed','shipping','delivered','cancelled') DEFAULT 'pending',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `total_amount_bacoin` decimal(15,2) DEFAULT NULL,
  `is_withdrawn` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `orders`
--

INSERT INTO `orders` (`id`, `user_id`, `address_id`, `order_date`, `total_amount`, `platform_fee`, `status`, `created_at`, `updated_at`, `total_amount_bacoin`, `is_withdrawn`) VALUES
(160, 4, 3, '2025-07-05 12:40:03', 0.00, 0.00, 'confirmed', '2025-07-05 12:40:03', '2025-07-05 12:40:03', 60000.00, 0),
(161, 4, 3, '2025-07-05 12:47:07', 0.00, 0.00, 'confirmed', '2025-07-05 12:47:07', '2025-07-05 12:47:07', 60000.00, 0),
(162, 4, 3, '2025-07-05 12:47:24', 60000.00, 10000.00, 'confirmed', '2025-07-05 12:47:24', '2025-07-05 12:49:30', NULL, 0),
(163, 4, 3, '2025-07-05 15:23:09', 50000.00, 0.00, 'pending', '2025-07-05 15:23:09', '2025-07-05 15:23:09', NULL, 0),
(164, 4, 3, '2025-07-05 15:24:14', 200000.00, 0.00, 'pending', '2025-07-05 15:24:14', '2025-07-05 15:24:14', NULL, 0),
(165, 4, 3, '2025-07-05 17:46:52', 200000.00, 0.00, 'pending', '2025-07-05 17:46:52', '2025-07-05 17:46:52', NULL, 0),
(166, 4, 3, '2025-07-05 17:54:07', 60000.00, 10000.00, 'pending', '2025-07-05 17:54:07', '2025-07-05 17:54:07', NULL, 0),
(167, 4, 3, '2025-07-05 17:58:58', 0.00, 0.00, 'confirmed', '2025-07-05 17:58:58', '2025-07-05 17:58:58', 200000.00, 0),
(168, 4, 3, '2025-07-05 18:22:31', 320000.00, 0.00, 'pending', '2025-07-05 18:22:31', '2025-07-05 18:22:31', NULL, 0),
(169, 4, 3, '2025-07-05 18:26:44', 70000.00, 0.00, 'confirmed', '2025-07-05 18:26:44', '2025-07-05 18:33:12', NULL, 0);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `order_items`
--

CREATE TABLE `order_items` (
  `id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `variant_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `price` decimal(15,2) NOT NULL,
  `platform_fee` decimal(15,2) DEFAULT 0.00 COMMENT 'Platform fee for this item',
  `price_bacoin` decimal(15,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `order_items`
--

INSERT INTO `order_items` (`id`, `order_id`, `product_id`, `variant_id`, `quantity`, `price`, `platform_fee`, `price_bacoin`) VALUES
(192, 160, 31, 27, 1, 60000.00, 10000.00, NULL),
(193, 161, 31, 27, 1, 60000.00, 10000.00, NULL),
(194, 162, 31, 27, 1, 60000.00, 10000.00, NULL),
(195, 163, 20, 23, 1, 50000.00, 0.00, NULL),
(196, 164, 4, 6, 1, 200000.00, 0.00, NULL),
(197, 165, 4, 6, 1, 200000.00, 0.00, NULL),
(198, 166, 31, 27, 1, 60000.00, 10000.00, NULL),
(199, 167, 4, 6, 1, 200000.00, 0.00, NULL),
(200, 168, 6, 7, 1, 320000.00, 0.00, NULL),
(201, 169, 21, 23, 1, 70000.00, 0.00, NULL);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `payments`
--

CREATE TABLE `payments` (
  `id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `payment_method` enum('COD','Bank','Momo','VNPAY','Other','BACoin') DEFAULT NULL,
  `amount` decimal(15,2) NOT NULL,
  `status` enum('pending','paid','failed','refunded') DEFAULT 'pending',
  `transaction_code` varchar(100) DEFAULT NULL,
  `paid_at` datetime DEFAULT NULL,
  `amount_bacoin` decimal(15,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `payments`
--

INSERT INTO `payments` (`id`, `order_id`, `payment_method`, `amount`, `status`, `transaction_code`, `paid_at`, `amount_bacoin`) VALUES
(160, 160, 'BACoin', 60000.00, 'paid', 'BACOIN2025070507400394529806', '2025-07-05 12:40:03', 60000.00),
(161, 161, 'BACoin', 60000.00, 'paid', 'BACOIN2025070507470743702154', '2025-07-05 12:47:07', 60000.00),
(162, 162, 'COD', 60000.00, 'paid', 'COD2025070507493020932910', '2025-07-05 07:49:30', NULL),
(163, 163, 'COD', 50000.00, 'pending', NULL, NULL, NULL),
(164, 164, 'COD', 200000.00, 'pending', NULL, NULL, NULL),
(165, 165, 'COD', 200000.00, 'pending', NULL, NULL, NULL),
(166, 166, 'COD', 60000.00, 'pending', NULL, NULL, NULL),
(167, 167, 'BACoin', 200000.00, 'paid', 'BACOIN2025070512585831095557', '2025-07-05 17:58:58', 200000.00),
(168, 168, 'COD', 320000.00, 'pending', NULL, NULL, NULL),
(169, 169, 'COD', 70000.00, 'paid', 'COD2025070513331201300862', '2025-07-05 13:33:12', NULL);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `products`
--

CREATE TABLE `products` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `category` varchar(100) NOT NULL,
  `gender_target` varchar(20) NOT NULL,
  `main_image` varchar(255) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL COMMENT 'user_id who created this product',
  `is_agency_product` tinyint(1) DEFAULT 0 COMMENT '1 if created by agency, 0 if by admin',
  `status` enum('pending','approved','rejected','active','inactive') DEFAULT 'pending',
  `platform_fee_rate` decimal(5,2) DEFAULT 20.00 COMMENT 'Platform fee rate in percentage',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `products`
--

INSERT INTO `products` (`id`, `name`, `description`, `category`, `gender_target`, `main_image`, `created_by`, `is_agency_product`, `status`, `platform_fee_rate`, `created_at`, `updated_at`) VALUES
(4, 'Áo đi biển', 'SIêu đẹp , năng động', 'T-Shirts', 'unisex', '685fc2bef398e_1751106238.jpg', 6, 0, 'active', 20.00, '2025-06-28 07:08:07', '2025-06-28 17:23:59'),
(6, 'Áo khoác', 'Ấm áp , thời trang', 'T-Shirts', 'unisex', '685fc2de852d4_1751106270.jpg', 6, 0, 'active', 20.00, '2025-06-28 17:24:30', '2025-06-28 17:24:50'),
(20, 'Áo sơ mi tay ngắn', 'Sơ mi basic', 'Shirts', 'unisex', '68655c05c1001_1751473157.jpg', 6, 0, 'active', 20.00, '2025-07-02 23:15:58', '2025-07-02 23:19:17'),
(21, 'Áo sơ mi tay dài', 'Tay dài basic 3 màu', 'T-Shirts', 'unisex', '68655bd79d893_1751473111.jpg', 6, 0, 'active', 20.00, '2025-07-02 23:18:31', '2025-07-02 23:18:31'),
(22, 'Đồ ngủ xinh', 'Đẹp', 'Loungewear', 'female', '68655c752294a_1751473269.jpg', 6, 0, 'active', 20.00, '2025-07-02 23:21:09', '2025-07-02 23:21:09'),
(23, 'Áo khoác kaki basic', 'Basic 4 màu', 'Jackets & Coats', 'male', '68655cbbda234_1751473339.jpg', 6, 0, 'active', 20.00, '2025-07-02 23:22:19', '2025-07-02 23:22:27'),
(24, 'Quần Jean', 'Basic 3 màu', 'Pants', 'unisex', '68655d4800f6e_1751473480.jpg', 6, 0, 'active', 20.00, '2025-07-02 23:24:40', '2025-07-02 23:24:40'),
(25, 'Quần Short', 'Basic 4 màu', 'Shorts', 'unisex', '68655d87dcedf_1751473543.jpg', 6, 0, 'active', 20.00, '2025-07-02 23:25:43', '2025-07-02 23:26:45'),
(26, 'Hoodie', 'Basic 4 màu', 'Hoodies', 'unisex', '68655dde89c5d_1751473630.jpg', 6, 0, 'active', 20.00, '2025-07-02 23:27:10', '2025-07-02 23:27:10'),
(27, 'Quần lót', 'Basic 3 màu', 'Underwear', 'unisex', '68655e5bbe542_1751473755.jpg', 6, 0, 'active', 20.00, '2025-07-02 23:29:15', '2025-07-02 23:29:15'),
(28, 'Áo thun co giãn', 'Basic 3 biến thể màu', 'Shirts', 'unisex', '686621153a9ea_1751523605.jpg', 9, 1, 'active', 20.00, '2025-07-03 13:20:05', '2025-07-03 13:25:43'),
(29, 'Áo khoác Vải nỉ', 'Basic 4 biến thể màu', 'Jackets & Coats', 'unisex', '6866213073b4c_1751523632.jpg', 9, 1, 'active', 20.00, '2025-07-03 13:20:32', '2025-07-03 13:25:42'),
(30, 'Quần tây', 'Basic 3 màu', 'Pants', 'unisex', '6866215492750_1751523668.jpg', 9, 1, 'active', 20.00, '2025-07-03 13:21:08', '2025-07-03 13:25:40'),
(31, 'Quần lửng', 'Fashion 4 màu', 'Shorts', 'unisex', '6866216d13605_1751523693.jpg', 9, 1, 'active', 20.00, '2025-07-03 13:21:33', '2025-07-03 13:25:39');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `product_approvals`
--

CREATE TABLE `product_approvals` (
  `id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `reviewed_by` int(11) DEFAULT NULL COMMENT 'admin user_id who reviewed',
  `status` enum('pending','approved','rejected') DEFAULT 'pending',
  `review_notes` text DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `product_approvals`
--

INSERT INTO `product_approvals` (`id`, `product_id`, `reviewed_by`, `status`, `review_notes`, `reviewed_at`, `created_at`) VALUES
(23, 28, NULL, '', NULL, NULL, '2025-07-03 13:20:05'),
(24, 29, NULL, '', NULL, NULL, '2025-07-03 13:20:32'),
(25, 30, NULL, '', NULL, NULL, '2025-07-03 13:21:08'),
(26, 31, NULL, '', NULL, NULL, '2025-07-03 13:21:33'),
(27, 31, NULL, 'pending', NULL, NULL, '2025-07-03 13:25:25'),
(28, 30, NULL, 'pending', NULL, NULL, '2025-07-03 13:25:27'),
(29, 29, NULL, 'pending', NULL, NULL, '2025-07-03 13:25:28'),
(30, 28, NULL, 'pending', NULL, NULL, '2025-07-03 13:25:29'),
(31, 31, 9, 'approved', '', '2025-07-03 13:25:39', '2025-07-03 13:25:39'),
(32, 30, 9, 'approved', '', '2025-07-03 13:25:40', '2025-07-03 13:25:40'),
(33, 29, 9, 'approved', '', '2025-07-03 13:25:42', '2025-07-03 13:25:42'),
(34, 28, 9, 'approved', '', '2025-07-03 13:25:43', '2025-07-03 13:25:43');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `product_combinations`
--

CREATE TABLE `product_combinations` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL COMMENT 'Tên tổ hợp sản phẩm',
  `description` text DEFAULT NULL COMMENT 'Mô tả tổ hợp',
  `image_url` varchar(255) DEFAULT NULL COMMENT 'Hình ảnh tổ hợp',
  `discount_price` decimal(15,2) DEFAULT NULL COMMENT 'Giá ưu đãi của tổ hợp',
  `original_price` decimal(15,2) DEFAULT NULL COMMENT 'Tổng giá gốc của các sản phẩm',
  `status` enum('active','inactive','pending','rejected') DEFAULT 'active' COMMENT 'Trạng thái tổ hợp',
  `created_by` int(11) NOT NULL COMMENT 'ID của admin/agency tạo tổ hợp',
  `creator_type` enum('admin','agency') NOT NULL COMMENT 'Loại người tạo (admin/agency)',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `product_combinations`
--

INSERT INTO `product_combinations` (`id`, `name`, `description`, `image_url`, `discount_price`, `original_price`, `status`, `created_by`, `creator_type`, `created_at`, `updated_at`) VALUES
(4, 'Combo Quần Áo Thời Thượng Sân Bay ', 'Kiểu dáng sân bay ', NULL, 150000.00, 180000.00, 'active', 6, 'admin', '2025-07-02 23:31:29', '2025-07-02 23:31:29'),
(6, 'Combo đơn giản ', 'basic fashion', NULL, 120000.00, 140000.00, 'active', 6, 'admin', '2025-07-02 23:33:01', '2025-07-02 23:33:01'),
(7, 'Vừa ăn Vừa ngủ', 'Combo quần áo phục vụ việc ăn lẫn ngủ', NULL, NULL, 110000.00, 'active', 6, 'admin', '2025-07-02 23:34:01', '2025-07-02 23:34:01'),
(9, 'TEst', 'opt', NULL, 200000.00, 290000.00, 'active', 6, 'admin', '2025-07-03 10:54:04', '2025-07-03 10:54:04'),
(11, '', NULL, NULL, NULL, 95677.00, 'active', 9, 'agency', '2025-07-03 13:46:50', '2025-07-03 14:47:10'),
(12, '', NULL, NULL, NULL, 105555.00, 'active', 9, 'agency', '2025-07-03 14:50:29', '2025-07-03 14:51:31'),
(13, '', NULL, NULL, NULL, 101232.00, 'active', 9, 'agency', '2025-07-03 14:54:43', '2025-07-03 14:55:00');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `product_combination_categories`
--

CREATE TABLE `product_combination_categories` (
  `id` int(11) NOT NULL,
  `combination_id` int(11) NOT NULL COMMENT 'ID của tổ hợp',
  `category_name` varchar(100) NOT NULL COMMENT 'Tên danh mục',
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `product_combination_categories`
--

INSERT INTO `product_combination_categories` (`id`, `combination_id`, `category_name`, `created_at`) VALUES
(7, 4, 'T-Shirts', '2025-07-02 23:31:29'),
(8, 4, 'Pants', '2025-07-02 23:31:29'),
(9, 4, 'Hoodies', '2025-07-02 23:31:29'),
(13, 6, 'Shirts', '2025-07-02 23:33:01'),
(14, 6, 'Shorts', '2025-07-02 23:33:01'),
(15, 6, 'Underwear', '2025-07-02 23:33:01'),
(16, 7, 'Loungewear', '2025-07-02 23:34:01'),
(17, 7, 'Pants', '2025-07-02 23:34:01'),
(18, 7, 'Shirts', '2025-07-02 23:34:01'),
(22, 9, 'T-Shirts', '2025-07-03 10:54:04'),
(23, 9, 'Shirts', '2025-07-03 10:54:04'),
(24, 9, 'Loungewear', '2025-07-03 10:54:04'),
(27, 11, 'Pants', '2025-07-03 13:46:50'),
(28, 11, 'Shorts', '2025-07-03 13:46:50'),
(29, 12, 'Shirts', '2025-07-03 14:50:29'),
(30, 12, 'Shorts', '2025-07-03 14:50:29'),
(31, 13, 'Pants', '2025-07-03 14:54:43'),
(32, 13, 'Shirts', '2025-07-03 14:54:43');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `product_combination_items`
--

CREATE TABLE `product_combination_items` (
  `id` int(11) NOT NULL,
  `combination_id` int(11) NOT NULL COMMENT 'ID của tổ hợp',
  `product_id` int(11) NOT NULL COMMENT 'ID của sản phẩm',
  `variant_id` int(11) DEFAULT NULL COMMENT 'ID của biến thể (nếu có)',
  `quantity` int(11) NOT NULL DEFAULT 1 COMMENT 'Số lượng sản phẩm trong tổ hợp',
  `price_in_combination` decimal(15,2) DEFAULT NULL COMMENT 'Giá của sản phẩm trong tổ hợp (có thể khác giá gốc)',
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `product_combination_items`
--

INSERT INTO `product_combination_items` (`id`, `combination_id`, `product_id`, `variant_id`, `quantity`, `price_in_combination`, `created_at`) VALUES
(8, 4, 24, 23, 1, NULL, '2025-07-02 23:31:29'),
(9, 4, 26, 24, 1, NULL, '2025-07-02 23:31:29'),
(13, 6, 20, 23, 1, NULL, '2025-07-02 23:33:01'),
(14, 6, 25, 23, 1, NULL, '2025-07-02 23:33:01'),
(15, 6, 27, 23, 1, NULL, '2025-07-02 23:33:01'),
(16, 7, 22, 23, 1, NULL, '2025-07-02 23:34:01'),
(17, 7, 24, 23, 1, NULL, '2025-07-02 23:34:01'),
(18, 7, 20, 23, 1, NULL, '2025-07-02 23:34:01'),
(22, 9, 4, 9, 1, NULL, '2025-07-03 10:54:04'),
(23, 9, 20, 23, 1, NULL, '2025-07-03 10:54:04'),
(24, 9, 22, 23, 1, NULL, '2025-07-03 10:54:04'),
(27, 11, 30, 29, 1, NULL, '2025-07-03 13:46:50'),
(28, 11, 31, 27, 1, NULL, '2025-07-03 13:46:50'),
(29, 12, 28, 32, 1, NULL, '2025-07-03 14:50:29'),
(30, 12, 31, 27, 1, NULL, '2025-07-03 14:50:29'),
(31, 13, 30, 29, 1, NULL, '2025-07-03 14:54:43'),
(32, 13, 28, 32, 1, NULL, '2025-07-03 14:54:43');

--
-- Bẫy `product_combination_items`
--
DELIMITER $$
CREATE TRIGGER `calculate_combination_original_price_delete` AFTER DELETE ON `product_combination_items` FOR EACH ROW BEGIN
    UPDATE product_combinations 
    SET original_price = (
        SELECT COALESCE(SUM(
            CASE 
                WHEN pci.price_in_combination IS NOT NULL THEN pci.price_in_combination * pci.quantity
                WHEN pv.price IS NOT NULL THEN pv.price * pci.quantity
                ELSE 0
            END
        ), 0)
        FROM product_combination_items pci
        LEFT JOIN product_variant pv ON pci.product_id = pv.product_id AND pci.variant_id = pv.variant_id
        WHERE pci.combination_id = OLD.combination_id
    )
    WHERE id = OLD.combination_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `calculate_combination_original_price_insert` AFTER INSERT ON `product_combination_items` FOR EACH ROW BEGIN
    UPDATE product_combinations 
    SET original_price = (
        SELECT COALESCE(SUM(
            CASE 
                WHEN pci.price_in_combination IS NOT NULL THEN pci.price_in_combination * pci.quantity
                WHEN pv.price IS NOT NULL THEN pv.price * pci.quantity
                ELSE 0
            END
        ), 0)
        FROM product_combination_items pci
        LEFT JOIN product_variant pv ON pci.product_id = pv.product_id AND pci.variant_id = pv.variant_id
        WHERE pci.combination_id = NEW.combination_id
    )
    WHERE id = NEW.combination_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `calculate_combination_original_price_update` AFTER UPDATE ON `product_combination_items` FOR EACH ROW BEGIN
    UPDATE product_combinations 
    SET original_price = (
        SELECT COALESCE(SUM(
            CASE 
                WHEN pci.price_in_combination IS NOT NULL THEN pci.price_in_combination * pci.quantity
                WHEN pv.price IS NOT NULL THEN pv.price * pci.quantity
                ELSE 0
            END
        ), 0)
        FROM product_combination_items pci
        LEFT JOIN product_variant pv ON pci.product_id = pv.product_id AND pci.variant_id = pv.variant_id
        WHERE pci.combination_id = NEW.combination_id
    )
    WHERE id = NEW.combination_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `product_variant`
--

CREATE TABLE `product_variant` (
  `product_id` int(11) NOT NULL,
  `variant_id` int(11) NOT NULL,
  `price` decimal(15,2) NOT NULL,
  `stock` int(11) NOT NULL DEFAULT 0,
  `image_url` varchar(255) DEFAULT NULL,
  `status` enum('active','inactive','out_of_stock') DEFAULT 'active',
  `price_bacoin` decimal(15,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `product_variant`
--

INSERT INTO `product_variant` (`product_id`, `variant_id`, `price`, `stock`, `image_url`, `status`, `price_bacoin`) VALUES
(4, 6, 200000.00, 861, '685fc4426c6ca_1751106626.jpg', 'active', 0.00),
(4, 7, 190000.00, 95, '685fc44a1726b_1751106634.jpg', 'active', 0.00),
(4, 9, 210000.00, 95, '685fc4571983c_1751106647.jpg', 'active', 0.00),
(6, 7, 320000.00, 80, '685fc63e59b33_1751107134.jpg', 'active', 0.00),
(6, 10, 300000.00, 207, '685fc65061fbc_1751107152.jpg', 'active', 0.00),
(6, 11, 350000.00, 191, '685fc4b6e7c7f_1751106742.jpg', 'active', 0.00),
(20, 23, 50000.00, 42, '68655b5c23857_1751472988.jpg', 'active', 0.00),
(20, 24, 55000.00, 50, '68655b74c3ce8_1751473012.jpg', 'active', NULL),
(20, 25, 60000.00, 50, '68655b97edd19_1751473047.jpg', 'active', NULL),
(21, 23, 70000.00, 48, '68655c38d9db5_1751473208.jpg', 'active', 0.00),
(21, 24, 60000.00, 50, '68655c506baa7_1751473232.jpg', 'active', 0.00),
(22, 23, 30000.00, 24, '68655c8a30882_1751473290.jpg', 'active', NULL),
(22, 24, 60000.00, 40, '68655c9e24689_1751473310.jpg', 'active', NULL),
(23, 23, 50000.00, 39, '68655cf533f28_1751473397.jpg', 'active', NULL),
(23, 24, 40000.00, 30, '68655d0567c0b_1751473413.jpg', 'active', NULL),
(23, 25, 50000.00, 50, '68655d1a340a3_1751473434.jpg', 'active', NULL),
(24, 23, 30000.00, 28, '68655d591feda_1751473497.jpg', 'active', NULL),
(24, 24, 50000.00, 50, '68655d68aebe7_1751473512.jpg', 'active', NULL),
(25, 23, 50000.00, 50, '68655d9a3caa5_1751473562.jpg', 'active', NULL),
(25, 24, 30000.00, 40, '68655da89b566_1751473576.jpg', 'active', NULL),
(25, 25, 40000.00, 50, '68655db875f4b_1751473592.jpg', 'active', NULL),
(26, 23, 30000.00, 30, '68655df0365fc_1751473648.jpg', 'active', NULL),
(26, 24, 40000.00, 39, '68655e00d0d9c_1751473664.jpg', 'active', NULL),
(26, 25, 60000.00, 40, '68655e133bdf6_1751473683.jpg', 'active', NULL),
(27, 23, 40000.00, 50, '68655e6c853d2_1751473772.jpg', 'active', NULL),
(27, 26, 50000.00, 50, '68655e7edeb35_1751473790.jpg', 'active', NULL),
(28, 32, 55555.00, 66, '6866225025b9a_1751523920.jpg', 'active', NULL),
(29, 30, 55555.00, 53, '6866220b8b04b_1751523851.jpg', 'active', NULL),
(29, 31, 4545464.00, 23, '68662231bd8fd_1751523889.jpg', 'active', NULL),
(30, 29, 45677.00, 443, '686621cf7252b_1751523791.jpg', 'active', NULL),
(31, 27, 50000.00, 22, '6866218c3a537_1751523724.jpg', 'active', NULL),
(31, 28, 4444.00, 555, '686621b03b1b2_1751523760.jpg', 'active', NULL);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `promotion`
--

CREATE TABLE `promotion` (
  `id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `original_price` decimal(10,2) NOT NULL,
  `converted_price` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `promotion`
--

INSERT INTO `promotion` (`id`, `name`, `original_price`, `converted_price`) VALUES
(1, 'Promotion 1', 100000.00, 130000.00),
(2, 'Promotion 2', 500000.00, 570000.00),
(3, 'Promotion 3', 1000000.00, 1200000.00);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(50) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `gender` enum('male','female','other') DEFAULT NULL,
  `dob` date DEFAULT NULL,
  `role` enum('user','admin','agency') DEFAULT 'user',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `balance` double(10,0) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `users`
--

INSERT INTO `users` (`id`, `username`, `email`, `phone`, `password`, `gender`, `dob`, `role`, `created_at`, `updated_at`, `balance`) VALUES
(4, 'user', 'user@gmail.com', '0967586754', '6ad14ba9986e3615423dfca256d04e3f', 'male', '2025-06-05', 'user', '2025-06-27 10:36:13', '2025-07-05 17:58:58', 2326711),
(6, 'admin', 'admin@gmail.com', '09675867543', '0192023a7bbd73250516f069df18b500', 'male', NULL, 'admin', '2025-06-27 10:38:00', '2025-07-05 17:58:58', 260000),
(9, 'agency', 'agency@gmail.com', '0123456788', 'ca08cd773aac01eb003a9d50dedce7fa', 'male', NULL, 'agency', '2025-06-30 23:30:57', '2025-07-05 12:47:07', 410000),
(10, 'tonbao', 'tonbaodfd1@gmail.com', '09123763121', '25f9e794323b453885f5181f1b624d0b', 'male', '2025-06-26', 'user', '2025-07-05 13:45:40', '2025-07-05 13:45:40', 0);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `user_addresses`
--

CREATE TABLE `user_addresses` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `address_line` varchar(255) NOT NULL,
  `city` varchar(100) NOT NULL,
  `province` varchar(100) NOT NULL,
  `postal_code` varchar(20) DEFAULT NULL,
  `is_default` tinyint(1) DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `user_addresses`
--

INSERT INTO `user_addresses` (`id`, `user_id`, `address_line`, `city`, `province`, `postal_code`, `is_default`, `created_at`) VALUES
(3, 4, 'Ben tre', 'Mo cay', 'Ben Tre', '42', 1, '2025-06-27 11:50:00'),
(8, 4, 'TPHCM', 'QUAN 8', 'CAO LO', '123', 0, '2025-06-27 12:04:51');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `variants`
--

CREATE TABLE `variants` (
  `id` int(11) NOT NULL,
  `sku` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `variants`
--

INSERT INTO `variants` (`id`, `sku`) VALUES
(23, '1'),
(24, '2'),
(10, '24'),
(25, '3'),
(26, '4'),
(4, '43'),
(5, '52'),
(6, '54'),
(8, '543'),
(9, '56'),
(7, '65'),
(11, '87'),
(13, 'AGENCY-12-686336d219c25'),
(14, 'AGENCY-13-68633a4e498d6'),
(15, 'AGENCY-14-686344c01186f'),
(16, 'AGENCY-15-686351ae04db7'),
(17, 'AGENCY-15-686351c431927'),
(18, 'AGENCY-16-6863521365b37'),
(19, 'AGENCY-17-68635789ec4ae'),
(20, 'AGENCY-18-68636b1eb9196'),
(21, 'AGENCY-18-68636b41283b2'),
(22, 'AGENCY-19-68636b8182d9e'),
(32, 'AGENCY-28-686622503bd2f'),
(30, 'AGENCY-29-6866220b9aca3'),
(31, 'AGENCY-29-68662231cb765'),
(29, 'AGENCY-30-686621cf831ec'),
(27, 'AGENCY-31-6866218c47746'),
(28, 'AGENCY-31-686621b04da5b'),
(12, 'AGENCY-TEST-001'),
(3, 'JEANS-BLUE-XL-NIKE');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `variant_attribute_values`
--

CREATE TABLE `variant_attribute_values` (
  `variant_id` int(11) NOT NULL,
  `attribute_value_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `variant_attribute_values`
--

INSERT INTO `variant_attribute_values` (`variant_id`, `attribute_value_id`) VALUES
(4, 12),
(4, 15),
(4, 16),
(5, 13),
(5, 15),
(5, 17),
(6, 12),
(6, 14),
(6, 18),
(7, 12),
(7, 15),
(7, 16),
(8, 13),
(8, 15),
(9, 12),
(9, 14),
(9, 18),
(10, 13),
(10, 15),
(10, 17),
(11, 12),
(11, 14),
(11, 18),
(12, 12),
(12, 16),
(13, 12),
(13, 15),
(13, 17),
(14, 13),
(14, 15),
(14, 17),
(14, 32),
(15, 13),
(15, 14),
(15, 16),
(15, 32),
(16, 13),
(16, 14),
(16, 16),
(16, 32),
(17, 12),
(17, 14),
(17, 16),
(17, 32),
(18, 12),
(18, 14),
(18, 16),
(19, 13),
(19, 14),
(19, 16),
(19, 32),
(20, 15),
(20, 16),
(21, 13),
(21, 15),
(21, 18),
(22, 13),
(22, 14),
(22, 18),
(23, 12),
(23, 14),
(23, 16),
(24, 12),
(24, 14),
(24, 17),
(25, 12),
(25, 14),
(25, 18),
(26, 12),
(26, 14),
(26, 17),
(27, 12),
(27, 15),
(27, 16),
(27, 32),
(28, 12),
(28, 14),
(28, 17),
(28, 31),
(29, 12),
(29, 15),
(29, 16),
(29, 31),
(30, 12),
(30, 14),
(30, 18),
(30, 31),
(31, 12),
(31, 15),
(31, 16),
(31, 31),
(32, 12),
(32, 15),
(32, 16),
(32, 31);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `vouchers`
--

CREATE TABLE `vouchers` (
  `id` int(11) NOT NULL,
  `voucher_code` varchar(50) NOT NULL COMMENT 'Mã voucher',
  `discount_amount` decimal(15,2) NOT NULL COMMENT 'Số tiền giảm giá',
  `quantity` int(11) NOT NULL DEFAULT 1 COMMENT 'Số lượng voucher có thể sử dụng',
  `start_date` datetime NOT NULL COMMENT 'Ngày bắt đầu hiệu lực',
  `end_date` datetime NOT NULL COMMENT 'Ngày kết thúc hiệu lực',
  `voucher_type` enum('all_products','specific_products','category_based') DEFAULT 'all_products',
  `category_filter` varchar(100) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `vouchers`
--

INSERT INTO `vouchers` (`id`, `voucher_code`, `discount_amount`, `quantity`, `start_date`, `end_date`, `voucher_type`, `category_filter`, `created_at`, `updated_at`) VALUES
(1, 'WELCOME2024', 50000.00, 100, '2024-01-01 00:00:00', '2024-12-31 23:59:59', 'all_products', NULL, '2025-07-05 14:30:46', '2025-07-05 14:30:46'),
(2, 'SUMMER50K', 50000.00, 50, '2024-06-01 00:00:00', '2024-08-31 23:59:59', 'all_products', NULL, '2025-07-05 14:30:46', '2025-07-05 14:30:46'),
(3, 'NEWYEAR100K', 100000.00, 30, '2024-12-01 00:00:00', '2025-01-31 23:59:59', 'all_products', NULL, '2025-07-05 14:30:46', '2025-07-05 14:30:46'),
(4, 'FLASH25K', 25000.00, 200, '2024-01-01 00:00:00', '2024-12-31 23:59:59', 'all_products', NULL, '2025-07-05 14:30:46', '2025-07-05 14:30:46'),
(5, 'VIP200K', 200000.00, 10, '2024-01-01 00:00:00', '2024-12-31 23:59:59', 'all_products', NULL, '2025-07-05 14:30:46', '2025-07-05 14:30:46'),
(7, 'EMMUONQUAMON', 100000.00, 1000, '2025-07-05 14:54:36', '2025-08-04 14:54:36', 'all_products', NULL, '2025-07-05 14:55:04', '2025-07-05 18:34:56');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `voucher_product_associations`
--

CREATE TABLE `voucher_product_associations` (
  `id` int(11) NOT NULL,
  `voucher_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `voucher_usage`
--

CREATE TABLE `voucher_usage` (
  `id` int(11) NOT NULL,
  `voucher_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `discount_applied` decimal(15,2) NOT NULL,
  `used_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `withdraw_agency`
--

CREATE TABLE `withdraw_agency` (
  `id` int(11) NOT NULL,
  `agency_id` int(11) NOT NULL,
  `total_sales` decimal(15,2) NOT NULL DEFAULT 0.00,
  `total_fee` decimal(15,2) NOT NULL DEFAULT 0.00,
  `personal_account_balance` decimal(15,2) NOT NULL DEFAULT 0.00,
  `available_balance` decimal(15,2) NOT NULL DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `withdraw_agency`
--

INSERT INTO `withdraw_agency` (`id`, `agency_id`, `total_sales`, `total_fee`, `personal_account_balance`, `available_balance`) VALUES
(6, 9, 120000.00, 24000.00, 100000.00, 0.00);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `withdraw_requests`
--

CREATE TABLE `withdraw_requests` (
  `id` int(11) NOT NULL,
  `agency_id` int(11) NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `note` text DEFAULT NULL,
  `status` enum('pending','approved','rejected','done') DEFAULT 'pending',
  `admin_note` text DEFAULT NULL,
  `reviewed_by` int(11) DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `withdraw_requests`
--

INSERT INTO `withdraw_requests` (`id`, `agency_id`, `amount`, `note`, `status`, `admin_note`, `reviewed_by`, `reviewed_at`, `created_at`) VALUES
(27, 9, 50000.00, 'gtr', 'approved', '', 6, '2025-07-05 12:49:48', '2025-07-05 12:49:42');

--
-- Chỉ mục cho các bảng đã đổ
--

--
-- Chỉ mục cho bảng `attributes`
--
ALTER TABLE `attributes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`),
  ADD KEY `created_by` (`created_by`);

--
-- Chỉ mục cho bảng `attribute_values`
--
ALTER TABLE `attribute_values`
  ADD PRIMARY KEY (`id`),
  ADD KEY `attribute_id` (`attribute_id`),
  ADD KEY `created_by` (`created_by`);

--
-- Chỉ mục cho bảng `bacoin_packages`
--
ALTER TABLE `bacoin_packages`
  ADD PRIMARY KEY (`id`);

--
-- Chỉ mục cho bảng `bacoin_transactions`
--
ALTER TABLE `bacoin_transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Chỉ mục cho bảng `cart_items`
--
ALTER TABLE `cart_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `product_id` (`product_id`,`variant_id`),
  ADD KEY `combination_id` (`combination_id`);

--
-- Chỉ mục cho bảng `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Chỉ mục cho bảng `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `address_id` (`address_id`);

--
-- Chỉ mục cho bảng `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_id` (`order_id`),
  ADD KEY `product_id` (`product_id`,`variant_id`);

--
-- Chỉ mục cho bảng `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_id` (`order_id`);

--
-- Chỉ mục cho bảng `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`id`),
  ADD KEY `created_by` (`created_by`);

--
-- Chỉ mục cho bảng `product_approvals`
--
ALTER TABLE `product_approvals`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `reviewed_by` (`reviewed_by`);

--
-- Chỉ mục cho bảng `product_combinations`
--
ALTER TABLE `product_combinations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `creator_type` (`creator_type`),
  ADD KEY `status` (`status`);

--
-- Chỉ mục cho bảng `product_combination_categories`
--
ALTER TABLE `product_combination_categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_combination_category` (`combination_id`,`category_name`),
  ADD KEY `combination_id` (`combination_id`);

--
-- Chỉ mục cho bảng `product_combination_items`
--
ALTER TABLE `product_combination_items`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_combination_product` (`combination_id`,`product_id`,`variant_id`),
  ADD KEY `combination_id` (`combination_id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `variant_id` (`variant_id`);

--
-- Chỉ mục cho bảng `product_variant`
--
ALTER TABLE `product_variant`
  ADD PRIMARY KEY (`product_id`,`variant_id`),
  ADD KEY `variant_id` (`variant_id`);

--
-- Chỉ mục cho bảng `promotion`
--
ALTER TABLE `promotion`
  ADD PRIMARY KEY (`id`);

--
-- Chỉ mục cho bảng `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `phone` (`phone`);

--
-- Chỉ mục cho bảng `user_addresses`
--
ALTER TABLE `user_addresses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Chỉ mục cho bảng `variants`
--
ALTER TABLE `variants`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `sku` (`sku`);

--
-- Chỉ mục cho bảng `variant_attribute_values`
--
ALTER TABLE `variant_attribute_values`
  ADD PRIMARY KEY (`variant_id`,`attribute_value_id`),
  ADD KEY `attribute_value_id` (`attribute_value_id`);

--
-- Chỉ mục cho bảng `vouchers`
--
ALTER TABLE `vouchers`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `voucher_code` (`voucher_code`);

--
-- Chỉ mục cho bảng `voucher_product_associations`
--
ALTER TABLE `voucher_product_associations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_voucher_product` (`voucher_id`,`product_id`),
  ADD KEY `voucher_id` (`voucher_id`),
  ADD KEY `product_id` (`product_id`);

--
-- Chỉ mục cho bảng `voucher_usage`
--
ALTER TABLE `voucher_usage`
  ADD PRIMARY KEY (`id`),
  ADD KEY `voucher_id` (`voucher_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `order_id` (`order_id`);

--
-- Chỉ mục cho bảng `withdraw_agency`
--
ALTER TABLE `withdraw_agency`
  ADD PRIMARY KEY (`id`),
  ADD KEY `agency_id` (`agency_id`);

--
-- Chỉ mục cho bảng `withdraw_requests`
--
ALTER TABLE `withdraw_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `agency_id` (`agency_id`);

--
-- AUTO_INCREMENT cho các bảng đã đổ
--

--
-- AUTO_INCREMENT cho bảng `attributes`
--
ALTER TABLE `attributes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT cho bảng `attribute_values`
--
ALTER TABLE `attribute_values`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT cho bảng `bacoin_packages`
--
ALTER TABLE `bacoin_packages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT cho bảng `bacoin_transactions`
--
ALTER TABLE `bacoin_transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=58;

--
-- AUTO_INCREMENT cho bảng `cart_items`
--
ALTER TABLE `cart_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=153;

--
-- AUTO_INCREMENT cho bảng `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=134;

--
-- AUTO_INCREMENT cho bảng `orders`
--
ALTER TABLE `orders`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=170;

--
-- AUTO_INCREMENT cho bảng `order_items`
--
ALTER TABLE `order_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=202;

--
-- AUTO_INCREMENT cho bảng `payments`
--
ALTER TABLE `payments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=170;

--
-- AUTO_INCREMENT cho bảng `products`
--
ALTER TABLE `products`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT cho bảng `product_approvals`
--
ALTER TABLE `product_approvals`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;

--
-- AUTO_INCREMENT cho bảng `product_combinations`
--
ALTER TABLE `product_combinations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT cho bảng `product_combination_categories`
--
ALTER TABLE `product_combination_categories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT cho bảng `product_combination_items`
--
ALTER TABLE `product_combination_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT cho bảng `promotion`
--
ALTER TABLE `promotion`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT cho bảng `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT cho bảng `user_addresses`
--
ALTER TABLE `user_addresses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT cho bảng `variants`
--
ALTER TABLE `variants`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT cho bảng `vouchers`
--
ALTER TABLE `vouchers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT cho bảng `voucher_product_associations`
--
ALTER TABLE `voucher_product_associations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT cho bảng `voucher_usage`
--
ALTER TABLE `voucher_usage`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT cho bảng `withdraw_agency`
--
ALTER TABLE `withdraw_agency`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT cho bảng `withdraw_requests`
--
ALTER TABLE `withdraw_requests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- Các ràng buộc cho các bảng đã đổ
--

--
-- Các ràng buộc cho bảng `attributes`
--
ALTER TABLE `attributes`
  ADD CONSTRAINT `attributes_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Các ràng buộc cho bảng `attribute_values`
--
ALTER TABLE `attribute_values`
  ADD CONSTRAINT `attribute_values_ibfk_1` FOREIGN KEY (`attribute_id`) REFERENCES `attributes` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `attribute_values_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Các ràng buộc cho bảng `bacoin_transactions`
--
ALTER TABLE `bacoin_transactions`
  ADD CONSTRAINT `bacoin_transactions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `cart_items`
--
ALTER TABLE `cart_items`
  ADD CONSTRAINT `cart_items_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `cart_items_ibfk_2` FOREIGN KEY (`product_id`,`variant_id`) REFERENCES `product_variant` (`product_id`, `variant_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `cart_items_ibfk_3` FOREIGN KEY (`combination_id`) REFERENCES `product_combinations` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`address_id`) REFERENCES `user_addresses` (`id`);

--
-- Các ràng buộc cho bảng `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`product_id`,`variant_id`) REFERENCES `product_variant` (`product_id`, `variant_id`);

--
-- Các ràng buộc cho bảng `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `products`
--
ALTER TABLE `products`
  ADD CONSTRAINT `products_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Các ràng buộc cho bảng `product_approvals`
--
ALTER TABLE `product_approvals`
  ADD CONSTRAINT `product_approvals_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `product_approvals_ibfk_2` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Các ràng buộc cho bảng `product_combinations`
--
ALTER TABLE `product_combinations`
  ADD CONSTRAINT `product_combinations_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `product_combination_categories`
--
ALTER TABLE `product_combination_categories`
  ADD CONSTRAINT `product_combination_categories_ibfk_1` FOREIGN KEY (`combination_id`) REFERENCES `product_combinations` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `product_combination_items`
--
ALTER TABLE `product_combination_items`
  ADD CONSTRAINT `product_combination_items_ibfk_1` FOREIGN KEY (`combination_id`) REFERENCES `product_combinations` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `product_combination_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `product_combination_items_ibfk_3` FOREIGN KEY (`variant_id`) REFERENCES `variants` (`id`) ON DELETE SET NULL;

--
-- Các ràng buộc cho bảng `product_variant`
--
ALTER TABLE `product_variant`
  ADD CONSTRAINT `product_variant_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `product_variant_ibfk_2` FOREIGN KEY (`variant_id`) REFERENCES `variants` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `user_addresses`
--
ALTER TABLE `user_addresses`
  ADD CONSTRAINT `user_addresses_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `variant_attribute_values`
--
ALTER TABLE `variant_attribute_values`
  ADD CONSTRAINT `variant_attribute_values_ibfk_1` FOREIGN KEY (`variant_id`) REFERENCES `variants` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `variant_attribute_values_ibfk_2` FOREIGN KEY (`attribute_value_id`) REFERENCES `attribute_values` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `voucher_product_associations`
--
ALTER TABLE `voucher_product_associations`
  ADD CONSTRAINT `voucher_product_associations_ibfk_1` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `voucher_product_associations_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `voucher_usage`
--
ALTER TABLE `voucher_usage`
  ADD CONSTRAINT `voucher_usage_ibfk_1` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `voucher_usage_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `voucher_usage_ibfk_3` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `withdraw_agency`
--
ALTER TABLE `withdraw_agency`
  ADD CONSTRAINT `withdraw_agency_ibfk_1` FOREIGN KEY (`agency_id`) REFERENCES `users` (`id`);

--
-- Các ràng buộc cho bảng `withdraw_requests`
--
ALTER TABLE `withdraw_requests`
  ADD CONSTRAINT `withdraw_requests_ibfk_1` FOREIGN KEY (`agency_id`) REFERENCES `users` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
