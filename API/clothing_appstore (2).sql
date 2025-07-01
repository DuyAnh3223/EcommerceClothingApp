-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jul 01, 2025 at 08:37 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `clothing_appstore`
--

-- --------------------------------------------------------

--
-- Table structure for table `attributes`
--

CREATE TABLE `attributes` (
  `id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `created_by` int(11) DEFAULT NULL COMMENT 'user_id who created this attribute',
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `attributes`
--

INSERT INTO `attributes` (`id`, `name`, `created_by`, `created_at`) VALUES
(1, 'color', 6, '2025-06-27 10:35:00'),
(2, 'size', 6, '2025-06-27 10:35:00'),
(3, 'brand', 6, '2025-06-27 10:35:00'),
(22, 'style', 9, '2025-07-01 08:16:41');

-- --------------------------------------------------------

--
-- Table structure for table `attribute_values`
--

CREATE TABLE `attribute_values` (
  `id` int(11) NOT NULL,
  `attribute_id` int(11) NOT NULL,
  `value` varchar(50) NOT NULL,
  `created_by` int(11) DEFAULT NULL COMMENT 'user_id who created this attribute value'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `attribute_values`
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
-- Table structure for table `cart_items`
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
-- Table structure for table `notifications`
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
-- Dumping data for table `notifications`
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
(61, 4, 'Thanh toán thành công', 'Đơn hàng #71 đã được thanh toán thành công qua VNPAY. Mã giao dịch: 15045538', 'order_status', 0, '2025-06-29 15:00:50'),
(62, 4, 'Thanh toán thành công', 'Đơn hàng #101 đã được thanh toán thành công qua VNPAY. Mã giao dịch: 15047235', 'order_status', 0, '2025-06-30 12:45:19'),
(63, 4, 'Thanh toán thành công', 'Đơn hàng #105 đã được thanh toán thành công qua VNPAY. Mã giao dịch: 15047266', 'order_status', 0, '2025-06-30 13:17:48'),
(64, 6, 'Sản phẩm mới cần duyệt', 'Sản phẩm \'A\' từ agency cần được duyệt.', 'product_approval', 0, '2025-07-01 09:15:37'),
(65, 9, 'Sản phẩm đã được duyệt', 'Sản phẩm \'A\' đã được admin duyệt và sẽ được hiển thị trên cửa hàng.', 'product_approval', 0, '2025-07-01 10:01:58'),
(66, 6, 'Sản phẩm mới cần duyệt', 'Sản phẩm \'Quần da bò\' từ agency cần được duyệt.', 'product_approval', 0, '2025-07-01 10:12:28'),
(67, 6, 'Sản phẩm mới cần duyệt', 'Sản phẩm \'Vét Nam Tính\' từ agency cần được duyệt.', 'product_approval', 0, '2025-07-01 10:13:20'),
(68, 6, 'Sản phẩm mới cần duyệt', 'Sản phẩm \'Áo khoác thể thao\' từ agency cần được duyệt.', 'product_approval', 0, '2025-07-01 10:35:42'),
(69, 9, 'Sản phẩm đã được duyệt', 'Sản phẩm \'Áo khoác thể thao\' đã được admin duyệt và sẽ được hiển thị trên cửa hàng.', 'product_approval', 0, '2025-07-01 10:37:48'),
(70, 9, 'Sản phẩm bị từ chối', 'Sản phẩm \'Quần da bò\' đã bị admin từ chối. Lý do: Quá nhiều tồn kho', 'product_approval', 0, '2025-07-01 10:38:01'),
(71, 9, 'Sản phẩm đã được duyệt', 'Sản phẩm \'Vét Nam Tính\' đã được admin duyệt và sẽ được hiển thị trên cửa hàng.', 'product_approval', 0, '2025-07-01 10:44:04'),
(72, 6, 'Sản phẩm mới cần duyệt', 'Sản phẩm \'Quần da bò\' từ agency cần được duyệt.', 'product_approval', 0, '2025-07-01 11:57:33'),
(73, 6, 'Sản phẩm mới cần duyệt', 'Sản phẩm \'Đồ ngủ\' từ agency cần được duyệt.', 'product_approval', 0, '2025-07-01 12:00:55'),
(74, 6, 'Sản phẩm mới cần duyệt', 'Sản phẩm \'Áo thun co giãn\' từ agency cần được duyệt.', 'product_approval', 0, '2025-07-01 12:01:01'),
(75, 9, 'Sản phẩm bị từ chối', 'Sản phẩm \'Áo thun co giãn\' đã bị admin từ chối. Lý do: Biến thể không hợp lệ', 'product_approval', 0, '2025-07-01 12:02:07'),
(76, 9, 'Sản phẩm đã được duyệt', 'Sản phẩm \'Đồ ngủ\' đã được admin duyệt và sẽ được hiển thị trên cửa hàng.', 'product_approval', 0, '2025-07-01 12:02:41'),
(77, 9, 'Sản phẩm bị từ chối', 'Sản phẩm \'Quần da bò\' đã bị admin từ chối. Lý do: Tồn kho không hợp lệ', 'product_approval', 0, '2025-07-01 12:03:06');

-- --------------------------------------------------------

--
-- Table structure for table `orders`
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
-- Dumping data for table `orders`
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
(71, 4, 3, '2025-06-29 15:00:05', 200000.00, 0.00, 'confirmed', '2025-06-29 15:00:05', '2025-06-29 15:00:50'),
(72, 4, 3, '2025-06-30 07:35:50', 30000.00, 0.00, 'pending', '2025-06-30 07:35:50', '2025-06-30 07:35:50'),
(73, 4, 3, '2025-06-30 07:35:56', 30000.00, 0.00, 'pending', '2025-06-30 07:35:56', '2025-06-30 07:35:56'),
(74, 4, 3, '2025-06-30 07:36:00', 30000.00, 0.00, 'pending', '2025-06-30 07:36:00', '2025-06-30 07:36:00'),
(75, 4, 3, '2025-06-30 07:36:34', 10000.00, 0.00, 'pending', '2025-06-30 07:36:34', '2025-06-30 07:36:34'),
(76, 4, 3, '2025-06-30 07:36:52', 10000.00, 0.00, 'pending', '2025-06-30 07:36:52', '2025-06-30 07:36:52'),
(77, 4, 3, '2025-06-30 07:37:08', 350000.00, 0.00, 'pending', '2025-06-30 07:37:08', '2025-06-30 07:37:08'),
(78, 4, 3, '2025-06-30 07:37:09', 350000.00, 0.00, 'pending', '2025-06-30 07:37:09', '2025-06-30 07:37:09'),
(79, 4, 3, '2025-06-30 07:37:10', 350000.00, 0.00, 'pending', '2025-06-30 07:37:10', '2025-06-30 07:37:10'),
(80, 4, 3, '2025-06-30 07:37:11', 350000.00, 0.00, 'pending', '2025-06-30 07:37:11', '2025-06-30 07:37:11'),
(81, 4, 3, '2025-06-30 07:37:11', 350000.00, 0.00, 'pending', '2025-06-30 07:37:11', '2025-06-30 07:37:11'),
(82, 4, 3, '2025-06-30 07:37:11', 350000.00, 0.00, 'pending', '2025-06-30 07:37:11', '2025-06-30 07:37:11'),
(83, 4, 3, '2025-06-30 07:37:12', 350000.00, 0.00, 'pending', '2025-06-30 07:37:12', '2025-06-30 07:37:12'),
(84, 4, 3, '2025-06-30 07:37:12', 350000.00, 0.00, 'pending', '2025-06-30 07:37:12', '2025-06-30 07:37:12'),
(85, 4, 3, '2025-06-30 07:56:01', 350000.00, 0.00, 'pending', '2025-06-30 07:56:01', '2025-06-30 07:56:01'),
(86, 4, 3, '2025-06-30 09:26:10', 600000.00, 0.00, 'pending', '2025-06-30 09:26:10', '2025-06-30 09:26:10'),
(87, 4, 3, '2025-06-30 09:26:12', 600000.00, 0.00, 'pending', '2025-06-30 09:26:12', '2025-06-30 09:26:12'),
(88, 4, 3, '2025-06-30 09:26:12', 600000.00, 0.00, 'pending', '2025-06-30 09:26:12', '2025-06-30 09:26:12'),
(89, 4, 3, '2025-06-30 09:26:12', 600000.00, 0.00, 'pending', '2025-06-30 09:26:12', '2025-06-30 09:26:12'),
(90, 4, 3, '2025-06-30 09:26:13', 600000.00, 0.00, 'pending', '2025-06-30 09:26:13', '2025-06-30 09:26:13'),
(91, 4, 3, '2025-06-30 09:26:13', 600000.00, 0.00, 'pending', '2025-06-30 09:26:13', '2025-06-30 09:26:13'),
(92, 4, 3, '2025-06-30 09:26:13', 600000.00, 0.00, 'pending', '2025-06-30 09:26:13', '2025-06-30 09:26:13'),
(93, 4, 3, '2025-06-30 09:26:13', 600000.00, 0.00, 'pending', '2025-06-30 09:26:13', '2025-06-30 09:26:13'),
(94, 4, 3, '2025-06-30 09:26:13', 600000.00, 0.00, 'pending', '2025-06-30 09:26:13', '2025-06-30 09:26:13'),
(95, 4, 3, '2025-06-30 09:26:14', 600000.00, 0.00, 'pending', '2025-06-30 09:26:14', '2025-06-30 09:26:14'),
(96, 4, 3, '2025-06-30 09:26:14', 600000.00, 0.00, 'pending', '2025-06-30 09:26:14', '2025-06-30 09:26:14'),
(97, 4, 3, '2025-06-30 09:26:14', 600000.00, 0.00, 'pending', '2025-06-30 09:26:14', '2025-06-30 09:26:14'),
(98, 4, 3, '2025-06-30 09:26:14', 600000.00, 0.00, 'pending', '2025-06-30 09:26:14', '2025-06-30 09:26:14'),
(99, 4, 3, '2025-06-30 09:26:14', 600000.00, 0.00, 'pending', '2025-06-30 09:26:14', '2025-06-30 09:26:14'),
(100, 4, 3, '2025-06-30 09:28:22', 800000.00, 0.00, 'pending', '2025-06-30 09:28:22', '2025-06-30 09:28:22'),
(101, 4, 3, '2025-06-30 12:43:57', 230000.00, 0.00, 'confirmed', '2025-06-30 12:43:57', '2025-06-30 12:45:19'),
(102, 4, 3, '2025-06-30 12:55:00', 620000.00, 0.00, 'pending', '2025-06-30 12:55:00', '2025-06-30 12:55:00'),
(103, 4, 3, '2025-06-30 12:55:15', 520000.00, 0.00, 'pending', '2025-06-30 12:55:15', '2025-06-30 12:55:15'),
(104, 4, 3, '2025-06-30 13:00:59', 210000.00, 0.00, 'pending', '2025-06-30 13:00:59', '2025-06-30 13:00:59'),
(105, 4, 3, '2025-06-30 13:17:21', 230000.00, 0.00, 'confirmed', '2025-06-30 13:17:21', '2025-06-30 13:17:48');

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
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
-- Dumping data for table `order_items`
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
(83, 71, 4, 6, 1, 200000.00, 0.00),
(84, 72, 3, 4, 3, 10000.00, 0.00),
(85, 73, 3, 4, 3, 10000.00, 0.00),
(86, 74, 3, 4, 3, 10000.00, 0.00),
(87, 75, 3, 4, 1, 10000.00, 0.00),
(88, 76, 3, 4, 1, 10000.00, 0.00),
(89, 77, 6, 11, 1, 350000.00, 0.00),
(90, 78, 6, 11, 1, 350000.00, 0.00),
(91, 79, 6, 11, 1, 350000.00, 0.00),
(92, 80, 6, 11, 1, 350000.00, 0.00),
(93, 81, 6, 11, 1, 350000.00, 0.00),
(94, 82, 6, 11, 1, 350000.00, 0.00),
(95, 83, 6, 11, 1, 350000.00, 0.00),
(96, 84, 6, 11, 1, 350000.00, 0.00),
(97, 85, 6, 11, 1, 350000.00, 0.00),
(98, 86, 4, 6, 3, 200000.00, 0.00),
(99, 87, 4, 6, 3, 200000.00, 0.00),
(100, 88, 4, 6, 3, 200000.00, 0.00),
(101, 89, 4, 6, 3, 200000.00, 0.00),
(102, 90, 4, 6, 3, 200000.00, 0.00),
(103, 91, 4, 6, 3, 200000.00, 0.00),
(104, 92, 4, 6, 3, 200000.00, 0.00),
(105, 93, 4, 6, 3, 200000.00, 0.00),
(106, 94, 4, 6, 3, 200000.00, 0.00),
(107, 95, 4, 6, 3, 200000.00, 0.00),
(108, 96, 4, 6, 3, 200000.00, 0.00),
(109, 97, 4, 6, 3, 200000.00, 0.00),
(110, 98, 4, 6, 3, 200000.00, 0.00),
(111, 99, 4, 6, 3, 200000.00, 0.00),
(112, 100, 4, 6, 4, 200000.00, 0.00),
(113, 101, 4, 6, 1, 200000.00, 0.00),
(114, 101, 3, 4, 3, 10000.00, 0.00),
(115, 102, 3, 5, 1, 110000.00, 0.00),
(116, 102, 4, 7, 1, 190000.00, 0.00),
(117, 102, 6, 7, 1, 320000.00, 0.00),
(118, 103, 6, 7, 1, 320000.00, 0.00),
(119, 103, 4, 6, 1, 200000.00, 0.00),
(120, 104, 4, 6, 1, 200000.00, 0.00),
(121, 104, 3, 4, 1, 10000.00, 0.00),
(122, 105, 4, 6, 1, 200000.00, 0.00),
(123, 105, 3, 4, 3, 10000.00, 0.00);

-- --------------------------------------------------------

--
-- Table structure for table `payments`
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
-- Dumping data for table `payments`
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
(72, 71, 'VNPAY', 200000.00, 'paid', '15045538', '2025-06-29 15:00:50'),
(73, 72, 'VNPAY', 30000.00, 'pending', NULL, NULL),
(74, 73, 'VNPAY', 30000.00, 'pending', NULL, NULL),
(75, 74, 'COD', 30000.00, 'pending', NULL, NULL),
(76, 75, 'VNPAY', 10000.00, 'pending', NULL, NULL),
(77, 76, 'COD', 10000.00, 'pending', NULL, NULL),
(78, 77, 'VNPAY', 350000.00, 'pending', NULL, NULL),
(79, 78, 'VNPAY', 350000.00, 'pending', NULL, NULL),
(80, 79, 'VNPAY', 350000.00, 'pending', NULL, NULL),
(81, 80, 'VNPAY', 350000.00, 'pending', NULL, NULL),
(82, 81, 'VNPAY', 350000.00, 'pending', NULL, NULL),
(83, 82, 'VNPAY', 350000.00, 'pending', NULL, NULL),
(84, 83, 'VNPAY', 350000.00, 'pending', NULL, NULL),
(85, 84, 'VNPAY', 350000.00, 'pending', NULL, NULL),
(86, 85, 'VNPAY', 350000.00, 'pending', NULL, NULL),
(87, 86, 'VNPAY', 600000.00, 'pending', NULL, NULL),
(88, 87, 'VNPAY', 600000.00, 'pending', NULL, NULL),
(89, 88, 'VNPAY', 600000.00, 'pending', NULL, NULL),
(90, 89, 'VNPAY', 600000.00, 'pending', NULL, NULL),
(91, 90, 'VNPAY', 600000.00, 'pending', NULL, NULL),
(92, 91, 'VNPAY', 600000.00, 'pending', NULL, NULL),
(93, 92, 'VNPAY', 600000.00, 'pending', NULL, NULL),
(94, 93, 'VNPAY', 600000.00, 'pending', NULL, NULL),
(95, 94, 'VNPAY', 600000.00, 'pending', NULL, NULL),
(96, 95, 'VNPAY', 600000.00, 'pending', NULL, NULL),
(97, 96, 'VNPAY', 600000.00, 'pending', NULL, NULL),
(98, 97, 'VNPAY', 600000.00, 'pending', NULL, NULL),
(99, 98, 'VNPAY', 600000.00, 'pending', NULL, NULL),
(100, 99, 'VNPAY', 600000.00, 'pending', NULL, NULL),
(101, 100, 'VNPAY', 800000.00, 'pending', NULL, NULL),
(102, 101, 'VNPAY', 230000.00, 'paid', '15047235', '2025-06-30 12:45:19'),
(103, 102, 'COD', 620000.00, 'pending', NULL, NULL),
(104, 103, 'VNPAY', 520000.00, 'pending', NULL, NULL),
(105, 104, 'VNPAY', 210000.00, 'pending', NULL, NULL),
(106, 105, 'VNPAY', 230000.00, 'paid', '15047266', '2025-06-30 13:17:48');

-- --------------------------------------------------------

--
-- Table structure for table `products`
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
-- Dumping data for table `products`
--

INSERT INTO `products` (`id`, `name`, `description`, `category`, `gender_target`, `main_image`, `created_by`, `is_agency_product`, `status`, `platform_fee_rate`, `created_at`, `updated_at`) VALUES
(3, 'Áo thun', 'Thoáng mát , thoải mái', 'T-Shirts', 'unisex', '685fc2a4bf938_1751106212.jpg', 6, 0, 'active', 20.00, '2025-06-27 10:35:00', '2025-06-28 17:23:32'),
(4, 'Áo đi biển', 'SIêu đẹp , năng động', 'T-Shirts', 'unisex', '685fc2bef398e_1751106238.jpg', 6, 0, 'active', 20.00, '2025-06-28 07:08:07', '2025-06-28 17:23:59'),
(6, 'Áo khoác', 'Ấm áp , thời trang', 'T-Shirts', 'unisex', '685fc2de852d4_1751106270.jpg', 6, 0, 'active', 20.00, '2025-06-28 17:24:30', '2025-06-28 17:24:50'),
(15, 'Quần da bò', 'Da bò xịn, chính hãng, 1-1', 'Pants', 'male', '6863518fa7601_1751339407.jpg', 9, 1, 'rejected', 20.00, '2025-07-01 10:10:07', '2025-07-01 12:03:06'),
(18, 'Đồ ngủ', 'Thoáng mát', 'Loungewear', 'unisex', '68636b01e1d22_1751345921.jpg', 9, 1, 'active', 20.00, '2025-07-01 11:58:41', '2025-07-01 12:02:41'),
(19, 'Áo thun co giãn', 'Mềm mại', 'Shirts', 'unisex', '68636b66dbce9_1751346022.jpg', 9, 1, 'rejected', 20.00, '2025-07-01 12:00:22', '2025-07-01 12:02:07');

-- --------------------------------------------------------

--
-- Table structure for table `product_approvals`
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
-- Dumping data for table `product_approvals`
--

INSERT INTO `product_approvals` (`id`, `product_id`, `reviewed_by`, `status`, `review_notes`, `reviewed_at`, `created_at`) VALUES
(7, 15, 9, 'rejected', 'Quá nhiều tồn kho', '2025-07-01 10:38:01', '2025-07-01 10:10:07'),
(20, 19, 9, 'rejected', 'Biến thể không hợp lệ', '2025-07-01 12:02:07', '2025-07-01 12:02:07'),
(21, 18, 9, 'approved', '', '2025-07-01 12:02:41', '2025-07-01 12:02:41'),
(22, 15, 9, 'rejected', 'Tồn kho không hợp lệ', '2025-07-01 12:03:06', '2025-07-01 12:03:06');

-- --------------------------------------------------------

--
-- Table structure for table `product_combinations`
--

CREATE TABLE `product_combinations` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL COMMENT 'Tên tổ hợp sản phẩm',
  `description` text DEFAULT NULL COMMENT 'Mô tả tổ hợp',
  `image_url` varchar(255) DEFAULT NULL COMMENT 'Hình ảnh tổ hợp',
  `discount_price` decimal(15,2) DEFAULT NULL COMMENT 'Giá ưu đãi của tổ hợp',
  `original_price` decimal(15,2) DEFAULT NULL COMMENT 'Tổng giá gốc của các sản phẩm',
  `status` enum('active','inactive','pending') DEFAULT 'active' COMMENT 'Trạng thái tổ hợp',
  `created_by` int(11) NOT NULL COMMENT 'ID của admin/agency tạo tổ hợp',
  `creator_type` enum('admin','agency') NOT NULL COMMENT 'Loại người tạo (admin/agency)',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `product_combinations`
--

INSERT INTO `product_combinations` (`id`, `name`, `description`, `image_url`, `discount_price`, `original_price`, `status`, `created_by`, `creator_type`, `created_at`, `updated_at`) VALUES
(1, 'Combo Áo Thun + Quần Jean', 'Tổ hợp áo thun và quần jean phong cách casual', 'combo_1.jpg', 250000.00, 210000.00, 'active', 6, 'admin', '2025-07-01 13:28:16', '2025-07-01 13:28:16'),
(2, 'Bộ Đồ Thể Thao Nam', 'Bộ đồ thể thao gồm áo và quần short', 'combo_2.jpg', 180000.00, 300000.00, 'active', 6, 'admin', '2025-07-01 13:28:16', '2025-07-01 13:28:16'),
(3, 'Combo Áo Khoác + Áo Thun', 'Tổ hợp áo khoác và áo thun mùa đông', 'combo_3.jpg', 400000.00, 330000.00, 'active', 9, 'agency', '2025-07-01 13:28:16', '2025-07-01 13:28:16');

-- --------------------------------------------------------

--
-- Table structure for table `product_combination_categories`
--

CREATE TABLE `product_combination_categories` (
  `id` int(11) NOT NULL,
  `combination_id` int(11) NOT NULL COMMENT 'ID của tổ hợp',
  `category_name` varchar(100) NOT NULL COMMENT 'Tên danh mục',
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `product_combination_categories`
--

INSERT INTO `product_combination_categories` (`id`, `combination_id`, `category_name`, `created_at`) VALUES
(1, 1, 'T-Shirts', '2025-07-01 13:28:16'),
(2, 1, 'Pants', '2025-07-01 13:28:16'),
(3, 2, 'T-Shirts', '2025-07-01 13:28:16'),
(4, 2, 'Pants', '2025-07-01 13:28:16'),
(5, 3, 'T-Shirts', '2025-07-01 13:28:16'),
(6, 3, 'Suits & Blazers', '2025-07-01 13:28:16');

-- --------------------------------------------------------

--
-- Table structure for table `product_combination_items`
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
-- Dumping data for table `product_combination_items`
--

INSERT INTO `product_combination_items` (`id`, `combination_id`, `product_id`, `variant_id`, `quantity`, `price_in_combination`, `created_at`) VALUES
(1, 1, 3, 4, 1, 10000.00, '2025-07-01 13:28:16'),
(2, 1, 4, 6, 1, 200000.00, '2025-07-01 13:28:16'),
(3, 2, 3, 5, 1, 110000.00, '2025-07-01 13:28:16'),
(4, 2, 4, 7, 1, 190000.00, '2025-07-01 13:28:16'),
(5, 3, 6, 7, 1, 320000.00, '2025-07-01 13:28:16'),
(6, 3, 3, 4, 1, 10000.00, '2025-07-01 13:28:16');

--
-- Triggers `product_combination_items`
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
-- Table structure for table `product_variant`
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
-- Dumping data for table `product_variant`
--

INSERT INTO `product_variant` (`product_id`, `variant_id`, `price`, `stock`, `image_url`, `status`) VALUES
(3, 4, 10000.00, 169, '685fc3208d62a_1751106336.jpg', 'active'),
(3, 5, 110000.00, 118, '685fc347a1b41_1751106375.jpg', 'active'),
(3, 6, 120000.00, 200, '685fc3698f547_1751106409.jpg', 'active'),
(4, 6, 200000.00, 87, '685fc4426c6ca_1751106626.jpg', 'active'),
(4, 7, 190000.00, 95, '685fc44a1726b_1751106634.jpg', 'active'),
(4, 9, 210000.00, 99, '685fc4571983c_1751106647.jpg', 'active'),
(6, 7, 320000.00, 91, '685fc63e59b33_1751107134.jpg', 'active'),
(6, 10, 300000.00, 207, '685fc65061fbc_1751107152.jpg', 'active'),
(6, 11, 350000.00, 191, '685fc4b6e7c7f_1751106742.jpg', 'active'),
(15, 16, 400000.00, 20, '686351ade8d28_1751339437.jpg', 'active'),
(15, 17, 500000.00, 40, '686351c427a5c_1751339460.jpg', 'active'),
(18, 20, 500000.00, 40, '68636b1eadc9a_1751345950.jpg', 'active'),
(18, 21, 600000.00, 20, '68636b411c113_1751345985.jpg', 'active'),
(19, 22, 789000.00, 20, '68636b8177319_1751346049.jpg', 'active');

-- --------------------------------------------------------

--
-- Table structure for table `users`
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
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `email`, `phone`, `password`, `gender`, `dob`, `role`, `created_at`, `updated_at`) VALUES
(4, 'user', 'user@gmail.com', '0967586754', '6ad14ba9986e3615423dfca256d04e3f', 'male', '2025-06-05', 'user', '2025-06-27 10:36:13', '2025-06-27 11:57:17'),
(6, 'admin', 'admin@gmail.com', '09675867543', '0192023a7bbd73250516f069df18b500', 'male', NULL, 'admin', '2025-06-27 10:38:00', '2025-06-27 10:38:00'),
(9, 'agency', 'agency@gmail.com', '0123456788', 'ca08cd773aac01eb003a9d50dedce7fa', 'male', NULL, 'agency', '2025-06-30 23:30:57', '2025-06-30 23:30:57');

-- --------------------------------------------------------

--
-- Table structure for table `user_addresses`
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
-- Dumping data for table `user_addresses`
--

INSERT INTO `user_addresses` (`id`, `user_id`, `address_line`, `city`, `province`, `postal_code`, `is_default`, `created_at`) VALUES
(3, 4, 'Ben tre', 'Mo cay', 'Ben Tre', '42', 1, '2025-06-27 11:50:00'),
(8, 4, 'TPHCM', 'QUAN 8', 'CAO LO', '123', 0, '2025-06-27 12:04:51');

-- --------------------------------------------------------

--
-- Table structure for table `variants`
--

CREATE TABLE `variants` (
  `id` int(11) NOT NULL,
  `sku` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `variants`
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
(12, 'AGENCY-TEST-001'),
(3, 'JEANS-BLUE-XL-NIKE');

-- --------------------------------------------------------

--
-- Table structure for table `variant_attribute_values`
--

CREATE TABLE `variant_attribute_values` (
  `variant_id` int(11) NOT NULL,
  `attribute_value_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `variant_attribute_values`
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
(22, 18);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `attributes`
--
ALTER TABLE `attributes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`),
  ADD KEY `created_by` (`created_by`);

--
-- Indexes for table `attribute_values`
--
ALTER TABLE `attribute_values`
  ADD PRIMARY KEY (`id`),
  ADD KEY `attribute_id` (`attribute_id`),
  ADD KEY `created_by` (`created_by`);

--
-- Indexes for table `cart_items`
--
ALTER TABLE `cart_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `product_id` (`product_id`,`variant_id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `address_id` (`address_id`);

--
-- Indexes for table `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_id` (`order_id`),
  ADD KEY `product_id` (`product_id`,`variant_id`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_id` (`order_id`);

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`id`),
  ADD KEY `created_by` (`created_by`);

--
-- Indexes for table `product_approvals`
--
ALTER TABLE `product_approvals`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `reviewed_by` (`reviewed_by`);

--
-- Indexes for table `product_combinations`
--
ALTER TABLE `product_combinations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `creator_type` (`creator_type`),
  ADD KEY `status` (`status`);

--
-- Indexes for table `product_combination_categories`
--
ALTER TABLE `product_combination_categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_combination_category` (`combination_id`,`category_name`),
  ADD KEY `combination_id` (`combination_id`);

--
-- Indexes for table `product_combination_items`
--
ALTER TABLE `product_combination_items`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_combination_product` (`combination_id`,`product_id`,`variant_id`),
  ADD KEY `combination_id` (`combination_id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `variant_id` (`variant_id`);

--
-- Indexes for table `product_variant`
--
ALTER TABLE `product_variant`
  ADD PRIMARY KEY (`product_id`,`variant_id`),
  ADD KEY `variant_id` (`variant_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `phone` (`phone`);

--
-- Indexes for table `user_addresses`
--
ALTER TABLE `user_addresses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `variants`
--
ALTER TABLE `variants`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `sku` (`sku`);

--
-- Indexes for table `variant_attribute_values`
--
ALTER TABLE `variant_attribute_values`
  ADD PRIMARY KEY (`variant_id`,`attribute_value_id`),
  ADD KEY `attribute_value_id` (`attribute_value_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `attributes`
--
ALTER TABLE `attributes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT for table `attribute_values`
--
ALTER TABLE `attribute_values`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT for table `cart_items`
--
ALTER TABLE `cart_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=78;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=78;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=106;

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=124;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=107;

--
-- AUTO_INCREMENT for table `products`
--
ALTER TABLE `products`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT for table `product_approvals`
--
ALTER TABLE `product_approvals`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT for table `product_combinations`
--
ALTER TABLE `product_combinations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `product_combination_categories`
--
ALTER TABLE `product_combination_categories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `product_combination_items`
--
ALTER TABLE `product_combination_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `user_addresses`
--
ALTER TABLE `user_addresses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `variants`
--
ALTER TABLE `variants`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `attributes`
--
ALTER TABLE `attributes`
  ADD CONSTRAINT `attributes_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `attribute_values`
--
ALTER TABLE `attribute_values`
  ADD CONSTRAINT `attribute_values_ibfk_1` FOREIGN KEY (`attribute_id`) REFERENCES `attributes` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `attribute_values_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `cart_items`
--
ALTER TABLE `cart_items`
  ADD CONSTRAINT `cart_items_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `cart_items_ibfk_2` FOREIGN KEY (`product_id`,`variant_id`) REFERENCES `product_variant` (`product_id`, `variant_id`);

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`address_id`) REFERENCES `user_addresses` (`id`);

--
-- Constraints for table `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`product_id`,`variant_id`) REFERENCES `product_variant` (`product_id`, `variant_id`);

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `products`
--
ALTER TABLE `products`
  ADD CONSTRAINT `products_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `product_approvals`
--
ALTER TABLE `product_approvals`
  ADD CONSTRAINT `product_approvals_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `product_approvals_ibfk_2` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `product_combinations`
--
ALTER TABLE `product_combinations`
  ADD CONSTRAINT `product_combinations_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `product_combination_categories`
--
ALTER TABLE `product_combination_categories`
  ADD CONSTRAINT `product_combination_categories_ibfk_1` FOREIGN KEY (`combination_id`) REFERENCES `product_combinations` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `product_combination_items`
--
ALTER TABLE `product_combination_items`
  ADD CONSTRAINT `product_combination_items_ibfk_1` FOREIGN KEY (`combination_id`) REFERENCES `product_combinations` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `product_combination_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `product_combination_items_ibfk_3` FOREIGN KEY (`variant_id`) REFERENCES `variants` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `product_variant`
--
ALTER TABLE `product_variant`
  ADD CONSTRAINT `product_variant_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `product_variant_ibfk_2` FOREIGN KEY (`variant_id`) REFERENCES `variants` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_addresses`
--
ALTER TABLE `user_addresses`
  ADD CONSTRAINT `user_addresses_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `variant_attribute_values`
--
ALTER TABLE `variant_attribute_values`
  ADD CONSTRAINT `variant_attribute_values_ibfk_1` FOREIGN KEY (`variant_id`) REFERENCES `variants` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `variant_attribute_values_ibfk_2` FOREIGN KEY (`attribute_value_id`) REFERENCES `attribute_values` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
