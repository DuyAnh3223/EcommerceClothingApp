-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Máy chủ: 127.0.0.1
-- Thời gian đã tạo: Th6 29, 2025 lúc 10:02 AM
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
(3, 'brand', 6, '2025-06-27 10:35:00'),
(1, 'color', 6, '2025-06-27 10:35:00'),
(2, 'size', 6, '2025-06-27 10:35:00');

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
(18, 1, 'yellow', 6);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `cart_items`
--

CREATE TABLE `cart_items` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `variant_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT 1,
  `added_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
(8, 4, 'Chào mừng bạn đến với ứng dụng!', 'Cảm ơn bạn đã đăng ký. Chúng tôi hy vọng bạn sẽ có trải nghiệm mua sắm tuyệt vời.', 'other', 1, '2025-06-27 12:51:25'),
(9, 4, 'Khuyến mãi cuối tuần', 'Giảm giá 20% cho tất cả sản phẩm áo thun. Chỉ diễn ra trong 2 ngày!', 'sale', 1, '2025-06-27 12:51:25'),
(10, 4, 'Voucher sinh nhật', 'Chúc mừng sinh nhật! Bạn nhận được voucher giảm giá 50.000 VNĐ cho đơn hàng tiếp theo.', 'voucher', 1, '2025-06-27 12:51:25'),
(11, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #123 của bạn đã được xác nhận và đang được xử lý.', 'order_status', 1, '2025-06-27 12:51:25'),
(12, 4, 'Sản phẩm mới', 'Bộ sưu tập mùa hè 2024 đã có mặt. Khám phá ngay các sản phẩm mới nhất!', 'sale', 1, '2025-06-27 12:51:25'),
(13, 6, 'giam', '50', 'sale', 0, '2025-06-27 12:55:15'),
(14, 4, 'giam', '50', 'sale', 1, '2025-06-27 12:55:15'),
(17, 4, 'Cập nhật trạng thái đơn hàng', 'Đơn hàng #16 đã được cập nhật trạng thái thành: pending', 'order_status', 1, '2025-06-27 14:34:15'),
(18, 4, 'Cập nhật trạng thái đơn hàng', 'Đơn hàng #16 đã được cập nhật trạng thái thành: pending', 'order_status', 1, '2025-06-27 14:34:19'),
(19, 4, 'Đơn hàng đang được giao', 'Đơn hàng #16 của bạn đang được giao đến địa chỉ của bạn. Dự kiến giao trong 1-3 ngày.', 'order_status', 1, '2025-06-27 14:34:47'),
(20, 4, 'Cập nhật trạng thái đơn hàng', 'Đơn hàng #16 đã được cập nhật trạng thái thành: pending', 'order_status', 1, '2025-06-27 14:34:58'),
(21, 4, 'Cập nhật trạng thái đơn hàng', 'Đơn hàng #16 đã được cập nhật trạng thái thành: pending', 'order_status', 1, '2025-06-27 14:35:11'),
(22, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #16 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 350,000 VNĐ', 'order_status', 1, '2025-06-27 14:35:16'),
(27, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #16 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 350,000 VNĐ', 'order_status', 1, '2025-06-27 14:41:07'),
(28, 4, 'Cập nhật trạng thái đơn hàng', 'Đơn hàng #3 đã được cập nhật trạng thái thành: pending', 'order_status', 1, '2025-06-27 14:41:18'),
(30, 4, 'Đơn hàng đang được giao', 'Đơn hàng #10 của bạn đang được giao đến địa chỉ của bạn. Dự kiến giao trong 1-3 ngày.', 'order_status', 1, '2025-06-27 17:44:55'),
(31, 4, 'Cập nhật trạng thái đơn hàng', 'Đơn hàng #19 đã được cập nhật trạng thái thành: pending', 'order_status', 1, '2025-06-27 18:29:33'),
(32, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #21 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 560,000 VNĐ', 'order_status', 1, '2025-06-28 07:50:37'),
(33, 4, 'Đơn hàng đang được giao', 'Đơn hàng #21 của bạn đang được giao đến địa chỉ của bạn. Dự kiến giao trong 1-3 ngày.', 'order_status', 1, '2025-06-28 08:15:26'),
(34, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #3 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 1,302 VNĐ', 'order_status', 1, '2025-06-28 08:39:21'),
(35, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #21 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 560,000 VNĐ', 'order_status', 1, '2025-06-28 08:48:32'),
(36, 4, 'Đơn hàng đang được giao', 'Đơn hàng #21 của bạn đang được giao đến địa chỉ của bạn. Dự kiến giao trong 1-3 ngày.', 'order_status', 1, '2025-06-28 09:26:40'),
(37, 4, 'Đơn hàng đang được giao', 'Đơn hàng #21 của bạn đang được giao đến địa chỉ của bạn. Dự kiến giao trong 1-3 ngày.', 'order_status', 1, '2025-06-28 09:35:30'),
(38, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #22 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 500,000 VNĐ', 'order_status', 0, '2025-06-28 12:48:44'),
(39, 4, 'Đơn hàng đã được giao thành công', 'Đơn hàng #22 đã được giao thành công. Cảm ơn bạn đã mua hàng!', 'order_status', 0, '2025-06-28 12:50:54'),
(40, 4, 'Cập nhật trạng thái đơn hàng', 'Đơn hàng #21 đã được cập nhật trạng thái thành: pending', 'order_status', 0, '2025-06-28 12:52:21'),
(41, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #21 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 560,000 VNĐ', 'order_status', 0, '2025-06-28 12:52:23'),
(42, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #23 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 60,000 VNĐ', 'order_status', 0, '2025-06-28 12:53:54'),
(43, 4, 'Đơn hàng đã được giao thành công', 'Đơn hàng #23 đã được giao thành công. Cảm ơn bạn đã mua hàng!', 'order_status', 0, '2025-06-28 12:54:28'),
(44, 4, 'Đơn hàng đã bị hủy', 'Đơn hàng #23 đã bị hủy. Nếu có thắc mắc, vui lòng liên hệ với chúng tôi.', 'order_status', 0, '2025-06-28 12:54:39'),
(45, 4, 'Đơn hàng đang được giao', 'Đơn hàng #23 của bạn đang được giao đến địa chỉ của bạn. Dự kiến giao trong 1-3 ngày.', 'order_status', 0, '2025-06-28 12:55:13'),
(46, 4, 'Đơn hàng đang được giao', 'Đơn hàng #23 của bạn đang được giao đến địa chỉ của bạn. Dự kiến giao trong 1-3 ngày.', 'order_status', 0, '2025-06-28 12:55:52'),
(47, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #23 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 60,000 VNĐ', 'order_status', 0, '2025-06-28 12:56:42'),
(48, 4, 'Cập nhật trạng thái đơn hàng', 'Đơn hàng #23 đã được cập nhật trạng thái thành: pending', 'order_status', 0, '2025-06-28 12:59:23'),
(49, 4, 'Cập nhật trạng thái đơn hàng', 'Đơn hàng #22 đã được cập nhật trạng thái thành: pending', 'order_status', 0, '2025-06-28 13:00:07'),
(50, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #39 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 180,000 VNĐ', 'order_status', 0, '2025-06-28 15:02:47'),
(51, 4, 'Đơn hàng đã được xác nhận', 'Đơn hàng #40 của bạn đã được xác nhận và đang được xử lý. Tổng tiền: 60,000 VNĐ', 'order_status', 0, '2025-06-28 15:03:18'),
(52, 4, 'Thanh toán thành công', 'Đơn hàng #60 đã được thanh toán thành công qua VNPAY. Mã giao dịch: 15045443', 'order_status', 0, '2025-06-29 13:54:53'),
(53, 4, 'Thanh toán thành công', 'Đơn hàng #61 đã được thanh toán thành công qua VNPAY. Mã giao dịch: 15045453', 'order_status', 0, '2025-06-29 14:01:24'),
(54, 4, 'Thanh toán thành công', 'Đơn hàng #62 đã được thanh toán thành công qua VNPAY. Mã giao dịch: 15045468', 'order_status', 0, '2025-06-29 14:10:54'),
(55, 4, 'Thanh toán thành công', 'Đơn hàng #63 đã được thanh toán thành công qua VNPAY. Mã giao dịch: 15045476', 'order_status', 0, '2025-06-29 14:16:09'),
(56, 4, 'Thanh toán thành công', 'Đơn hàng #64 đã được thanh toán thành công qua VNPAY. Mã giao dịch: 15045482', 'order_status', 0, '2025-06-29 14:19:37'),
(57, 4, 'Thanh toán thành công', 'Đơn hàng #65 đã được thanh toán thành công qua VNPAY. Mã giao dịch: 15045487', 'order_status', 0, '2025-06-29 14:24:11'),
(58, 4, 'Thanh toán thành công', 'Đơn hàng #67 đã được thanh toán thành công qua VNPAY. Mã giao dịch: 15045522', 'order_status', 0, '2025-06-29 14:45:47'),
(59, 4, 'Thanh toán thành công', 'Đơn hàng #69 đã được thanh toán thành công qua VNPAY. Mã giao dịch: 15045528', 'order_status', 0, '2025-06-29 14:54:06'),
(60, 4, 'Thanh toán thành công', 'Đơn hàng #70 đã được thanh toán thành công qua VNPAY. Mã giao dịch: 15045532', 'order_status', 0, '2025-06-29 14:57:57'),
(61, 4, 'Thanh toán thành công', 'Đơn hàng #71 đã được thanh toán thành công qua VNPAY. Mã giao dịch: 15045538', 'order_status', 0, '2025-06-29 15:00:50');

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
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `orders`
--

INSERT INTO `orders` (`id`, `user_id`, `address_id`, `order_date`, `total_amount`, `platform_fee`, `status`, `created_at`, `updated_at`) VALUES
(3, 4, 3, '2025-06-27 12:07:25', 1302.00, 0.00, 'confirmed', '2025-06-27 12:07:25', '2025-06-28 08:39:21'),
(21, 4, 3, '2025-06-28 07:12:20', 560000.00, 0.00, 'confirmed', '2025-06-28 07:12:20', '2025-06-28 12:52:23'),
(22, 4, 3, '2025-06-28 12:48:14', 500000.00, 0.00, 'pending', '2025-06-28 12:48:14', '2025-06-28 13:00:07'),
(41, 4, 3, '2025-06-29 12:49:40', 210000.00, 0.00, 'pending', '2025-06-29 12:49:40', '2025-06-29 12:49:40'),
(42, 4, 3, '2025-06-29 12:49:41', 210000.00, 0.00, 'pending', '2025-06-29 12:49:41', '2025-06-29 12:49:41'),
(43, 4, 3, '2025-06-29 12:49:41', 210000.00, 0.00, 'pending', '2025-06-29 12:49:41', '2025-06-29 12:49:41'),
(44, 4, 3, '2025-06-29 12:49:41', 210000.00, 0.00, 'pending', '2025-06-29 12:49:41', '2025-06-29 12:49:41'),
(45, 4, 3, '2025-06-29 12:49:41', 210000.00, 0.00, 'pending', '2025-06-29 12:49:41', '2025-06-29 12:49:41'),
(46, 4, 3, '2025-06-29 12:57:59', 210000.00, 0.00, 'pending', '2025-06-29 12:57:59', '2025-06-29 12:57:59'),
(47, 4, 3, '2025-06-29 12:58:04', 210000.00, 0.00, 'pending', '2025-06-29 12:58:04', '2025-06-29 12:58:04'),
(48, 4, 3, '2025-06-29 13:03:17', 210000.00, 0.00, 'pending', '2025-06-29 13:03:17', '2025-06-29 13:03:17'),
(49, 4, 3, '2025-06-29 13:03:41', 200000.00, 0.00, 'pending', '2025-06-29 13:03:41', '2025-06-29 13:03:41'),
(50, 4, 3, '2025-06-29 13:03:52', 200000.00, 0.00, 'pending', '2025-06-29 13:03:52', '2025-06-29 13:03:52'),
(51, 4, 3, '2025-06-29 13:11:25', 190000.00, 0.00, 'pending', '2025-06-29 13:11:25', '2025-06-29 13:11:25'),
(52, 4, 3, '2025-06-29 13:21:04', 200000.00, 0.00, 'pending', '2025-06-29 13:21:04', '2025-06-29 13:21:04'),
(53, 4, 3, '2025-06-29 13:29:21', 440000.00, 0.00, 'pending', '2025-06-29 13:29:21', '2025-06-29 13:29:21'),
(54, 4, 3, '2025-06-29 13:36:56', 320000.00, 0.00, 'pending', '2025-06-29 13:36:56', '2025-06-29 13:36:56'),
(55, 4, 3, '2025-06-29 13:48:57', 10000.00, 0.00, 'pending', '2025-06-29 13:48:57', '2025-06-29 13:48:57'),
(56, 4, 3, '2025-06-29 13:49:08', 10000.00, 0.00, 'pending', '2025-06-29 13:49:08', '2025-06-29 13:49:08'),
(57, 4, 3, '2025-06-29 13:49:23', 10000.00, 0.00, 'pending', '2025-06-29 13:49:23', '2025-06-29 13:49:23'),
(58, 4, 3, '2025-06-29 13:50:20', 200000.00, 0.00, 'pending', '2025-06-29 13:50:20', '2025-06-29 13:50:20'),
(59, 4, 3, '2025-06-29 13:50:25', 10000.00, 0.00, 'pending', '2025-06-29 13:50:25', '2025-06-29 13:50:25'),
(60, 4, 3, '2025-06-29 13:54:15', 10000.00, 0.00, 'confirmed', '2025-06-29 13:54:15', '2025-06-29 13:54:53'),
(61, 4, 3, '2025-06-29 14:00:54', 200000.00, 0.00, 'confirmed', '2025-06-29 14:00:54', '2025-06-29 14:01:24'),
(62, 4, 3, '2025-06-29 14:09:15', 200000.00, 0.00, 'confirmed', '2025-06-29 14:09:15', '2025-06-29 14:10:54'),
(63, 4, 3, '2025-06-29 14:15:40', 200000.00, 0.00, 'confirmed', '2025-06-29 14:15:40', '2025-06-29 14:16:09'),
(64, 4, 3, '2025-06-29 14:19:09', 320000.00, 0.00, 'confirmed', '2025-06-29 14:19:09', '2025-06-29 14:19:37'),
(65, 4, 3, '2025-06-29 14:20:39', 320000.00, 0.00, 'confirmed', '2025-06-29 14:20:39', '2025-06-29 14:24:11'),
(66, 4, 3, '2025-06-29 14:29:53', 320000.00, 0.00, 'pending', '2025-06-29 14:29:53', '2025-06-29 14:29:53'),
(67, 4, 3, '2025-06-29 14:43:43', 200000.00, 0.00, 'confirmed', '2025-06-29 14:43:43', '2025-06-29 14:45:47'),
(68, 4, 3, '2025-06-29 14:53:24', 200000.00, 0.00, 'pending', '2025-06-29 14:53:24', '2025-06-29 14:53:24'),
(69, 4, 3, '2025-06-29 14:53:35', 200000.00, 0.00, 'confirmed', '2025-06-29 14:53:35', '2025-06-29 14:54:06'),
(70, 4, 3, '2025-06-29 14:57:33', 200000.00, 0.00, 'confirmed', '2025-06-29 14:57:33', '2025-06-29 14:57:57'),
(71, 4, 3, '2025-06-29 15:00:05', 200000.00, 0.00, 'confirmed', '2025-06-29 15:00:05', '2025-06-29 15:00:50');

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
  `platform_fee` decimal(15,2) DEFAULT 0.00 COMMENT 'Platform fee for this item'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `order_items`
--

INSERT INTO `order_items` (`id`, `order_id`, `product_id`, `variant_id`, `quantity`, `price`, `platform_fee`) VALUES
(4, 3, 3, 4, 3, 434.00, 0.00),
(24, 21, 3, 4, 1, 500000.00, 0.00),
(25, 21, 4, 6, 1, 60000.00, 0.00),
(26, 22, 3, 4, 1, 500000.00, 0.00),
(45, 41, 3, 4, 1, 10000.00, 0.00),
(46, 41, 4, 6, 1, 200000.00, 0.00),
(47, 42, 3, 4, 1, 10000.00, 0.00),
(48, 42, 4, 6, 1, 200000.00, 0.00),
(49, 43, 3, 4, 1, 10000.00, 0.00),
(50, 43, 4, 6, 1, 200000.00, 0.00),
(51, 44, 3, 4, 1, 10000.00, 0.00),
(52, 44, 4, 6, 1, 200000.00, 0.00),
(53, 45, 3, 4, 1, 10000.00, 0.00),
(54, 45, 4, 6, 1, 200000.00, 0.00),
(55, 46, 3, 4, 1, 10000.00, 0.00),
(56, 46, 4, 6, 1, 200000.00, 0.00),
(57, 47, 3, 4, 1, 10000.00, 0.00),
(58, 47, 4, 6, 1, 200000.00, 0.00),
(59, 48, 3, 4, 1, 10000.00, 0.00),
(60, 48, 4, 6, 1, 200000.00, 0.00),
(61, 49, 4, 6, 1, 200000.00, 0.00),
(62, 50, 4, 6, 1, 200000.00, 0.00),
(63, 51, 4, 7, 1, 190000.00, 0.00),
(64, 52, 4, 6, 1, 200000.00, 0.00),
(65, 53, 3, 5, 4, 110000.00, 0.00),
(66, 54, 6, 7, 1, 320000.00, 0.00),
(67, 55, 3, 4, 1, 10000.00, 0.00),
(68, 56, 3, 4, 1, 10000.00, 0.00),
(69, 57, 3, 4, 1, 10000.00, 0.00),
(70, 58, 4, 6, 1, 200000.00, 0.00),
(71, 59, 3, 4, 1, 10000.00, 0.00),
(72, 60, 3, 4, 1, 10000.00, 0.00),
(73, 61, 4, 6, 1, 200000.00, 0.00),
(74, 62, 4, 6, 1, 200000.00, 0.00),
(75, 63, 4, 6, 1, 200000.00, 0.00),
(76, 64, 6, 7, 1, 320000.00, 0.00),
(77, 65, 6, 7, 1, 320000.00, 0.00),
(78, 66, 6, 7, 1, 320000.00, 0.00),
(79, 67, 4, 6, 1, 200000.00, 0.00),
(80, 68, 4, 6, 1, 200000.00, 0.00),
(81, 69, 4, 6, 1, 200000.00, 0.00),
(82, 70, 4, 6, 1, 200000.00, 0.00),
(83, 71, 4, 6, 1, 200000.00, 0.00);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `payments`
--

CREATE TABLE `payments` (
  `id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `payment_method` enum('COD','Bank','Momo','VNPAY','Other') NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `status` enum('pending','paid','failed','refunded') DEFAULT 'pending',
  `transaction_code` varchar(100) DEFAULT NULL,
  `paid_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `payments`
--

INSERT INTO `payments` (`id`, `order_id`, `payment_method`, `amount`, `status`, `transaction_code`, `paid_at`) VALUES
(3, 3, 'COD', 1302.00, 'paid', 'COD2025062803392190298469', '2025-06-28 03:39:21'),
(21, 21, 'COD', 560000.00, 'paid', 'COD2025062807522380328235', '2025-06-28 07:52:23'),
(22, 22, 'COD', 500000.00, 'pending', NULL, NULL),
(42, 41, 'VNPAY', 210000.00, 'pending', NULL, NULL),
(43, 42, 'VNPAY', 210000.00, 'pending', NULL, NULL),
(44, 43, 'VNPAY', 210000.00, 'pending', NULL, NULL),
(45, 44, 'VNPAY', 210000.00, 'pending', NULL, NULL),
(46, 45, 'VNPAY', 210000.00, 'pending', NULL, NULL),
(47, 46, 'VNPAY', 210000.00, 'pending', NULL, NULL),
(48, 47, 'VNPAY', 210000.00, 'pending', NULL, NULL),
(49, 48, 'VNPAY', 210000.00, 'pending', NULL, NULL),
(50, 49, 'COD', 200000.00, 'pending', NULL, NULL),
(51, 50, 'VNPAY', 200000.00, 'pending', NULL, NULL),
(52, 51, 'VNPAY', 190000.00, 'pending', NULL, NULL),
(53, 52, 'VNPAY', 200000.00, 'pending', NULL, NULL),
(54, 53, 'VNPAY', 440000.00, 'pending', NULL, NULL),
(55, 54, 'VNPAY', 320000.00, 'pending', NULL, NULL),
(56, 55, 'VNPAY', 10000.00, 'pending', NULL, NULL),
(57, 56, 'VNPAY', 10000.00, 'pending', NULL, NULL),
(58, 57, 'VNPAY', 10000.00, 'pending', NULL, NULL),
(59, 58, 'VNPAY', 200000.00, 'pending', NULL, NULL),
(60, 59, 'VNPAY', 10000.00, 'pending', NULL, NULL),
(61, 60, 'VNPAY', 10000.00, 'paid', '15045443', '2025-06-29 13:54:53'),
(62, 61, 'VNPAY', 200000.00, 'paid', '15045453', '2025-06-29 14:01:24'),
(63, 62, 'VNPAY', 200000.00, 'paid', '15045468', '2025-06-29 14:10:54'),
(64, 63, 'VNPAY', 200000.00, 'paid', '15045476', '2025-06-29 14:16:09'),
(65, 64, 'VNPAY', 320000.00, 'paid', '15045482', '2025-06-29 14:19:37'),
(66, 65, 'VNPAY', 320000.00, 'paid', '15045487', '2025-06-29 14:24:11'),
(67, 66, 'VNPAY', 320000.00, 'pending', NULL, NULL),
(68, 67, 'VNPAY', 200000.00, 'paid', '15045522', '2025-06-29 14:45:47'),
(69, 68, 'COD', 200000.00, 'pending', NULL, NULL),
(70, 69, 'VNPAY', 200000.00, 'paid', '15045528', '2025-06-29 14:54:06'),
(71, 70, 'VNPAY', 200000.00, 'paid', '15045532', '2025-06-29 14:57:57'),
(72, 71, 'VNPAY', 200000.00, 'paid', '15045538', '2025-06-29 15:00:50');

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
(3, 'Áo thun', 'Thoáng mát , thoải mái', 'T-Shirts', 'unisex', '685fc2a4bf938_1751106212.jpg', 6, 0, 'active', 20.00, '2025-06-27 10:35:00', '2025-06-28 17:23:32'),
(4, 'Áo đi biển', 'SIêu đẹp , năng động', 'T-Shirts', 'unisex', '685fc2bef398e_1751106238.jpg', 6, 0, 'active', 20.00, '2025-06-28 07:08:07', '2025-06-28 17:23:59'),
(6, 'Áo khoác', 'Ấm áp , thời trang', 'T-Shirts', 'unisex', '685fc2de852d4_1751106270.jpg', 6, 0, 'active', 20.00, '2025-06-28 17:24:30', '2025-06-28 17:24:50');

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

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `product_reviews`
--

CREATE TABLE `product_reviews` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `rating` int(11) NOT NULL CHECK (`rating` between 1 and 5),
  `content` text DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `video_url` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
  `status` enum('active','inactive','out_of_stock') DEFAULT 'active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `product_variant`
--

INSERT INTO `product_variant` (`product_id`, `variant_id`, `price`, `stock`, `image_url`, `status`) VALUES
(3, 4, 10000.00, 187, '685fc3208d62a_1751106336.jpg', 'active'),
(3, 5, 110000.00, 119, '685fc347a1b41_1751106375.jpg', 'active'),
(3, 6, 120000.00, 200, '685fc3698f547_1751106409.jpg', 'active'),
(4, 6, 200000.00, 137, '685fc4426c6ca_1751106626.jpg', 'active'),
(4, 7, 190000.00, 96, '685fc44a1726b_1751106634.jpg', 'active'),
(4, 9, 210000.00, 99, '685fc4571983c_1751106647.jpg', 'active'),
(6, 7, 320000.00, 93, '685fc63e59b33_1751107134.jpg', 'active'),
(6, 10, 300000.00, 207, '685fc65061fbc_1751107152.jpg', 'active'),
(6, 11, 350000.00, 200, '685fc4b6e7c7f_1751106742.jpg', 'active');

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
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `users`
--

INSERT INTO `users` (`id`, `username`, `email`, `phone`, `password`, `gender`, `dob`, `role`, `created_at`, `updated_at`) VALUES
(4, 'user', 'user@gmail.com', '0967586754', '6ad14ba9986e3615423dfca256d04e3f', 'male', '2025-06-05', 'user', '2025-06-27 10:36:13', '2025-06-27 11:57:17'),
(6, 'admin', 'admin@gmail.com', '09675867543', '0192023a7bbd73250516f069df18b500', 'male', NULL, 'admin', '2025-06-27 10:38:00', '2025-06-27 10:38:00');


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
(10, '24'),
(4, '43'),
(5, '52'),
(6, '54'),
(8, '543'),
(9, '56'),
(7, '65'),
(11, '87'),
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
(11, 18);

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
-- Chỉ mục cho bảng `cart_items`
--
ALTER TABLE `cart_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `product_id` (`product_id`,`variant_id`);

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
-- Chỉ mục cho bảng `product_reviews`
--
ALTER TABLE `product_reviews`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `order_id` (`order_id`);

--
-- Chỉ mục cho bảng `product_variant`
--
ALTER TABLE `product_variant`
  ADD PRIMARY KEY (`product_id`,`variant_id`),
  ADD KEY `variant_id` (`variant_id`);

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
-- AUTO_INCREMENT cho các bảng đã đổ
--

--
-- AUTO_INCREMENT cho bảng `attributes`
--
ALTER TABLE `attributes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT cho bảng `attribute_values`
--
ALTER TABLE `attribute_values`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT cho bảng `cart_items`
--
ALTER TABLE `cart_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=63;

--
-- AUTO_INCREMENT cho bảng `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=62;

--
-- AUTO_INCREMENT cho bảng `orders`
--
ALTER TABLE `orders`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=72;

--
-- AUTO_INCREMENT cho bảng `order_items`
--
ALTER TABLE `order_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=84;

--
-- AUTO_INCREMENT cho bảng `payments`
--
ALTER TABLE `payments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=73;

--
-- AUTO_INCREMENT cho bảng `products`
--
ALTER TABLE `products`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT cho bảng `product_approvals`
--
ALTER TABLE `product_approvals`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT cho bảng `product_reviews`
--
ALTER TABLE `product_reviews`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT cho bảng `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT cho bảng `user_addresses`
--
ALTER TABLE `user_addresses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT cho bảng `variants`
--
ALTER TABLE `variants`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

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
-- Các ràng buộc cho bảng `cart_items`
--
ALTER TABLE `cart_items`
  ADD CONSTRAINT `cart_items_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `cart_items_ibfk_2` FOREIGN KEY (`product_id`,`variant_id`) REFERENCES `product_variant` (`product_id`, `variant_id`);

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
-- Các ràng buộc cho bảng `product_reviews`
--
ALTER TABLE `product_reviews`
  ADD CONSTRAINT `product_reviews_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `product_reviews_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`),
  ADD CONSTRAINT `product_reviews_ibfk_3` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`);

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
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
