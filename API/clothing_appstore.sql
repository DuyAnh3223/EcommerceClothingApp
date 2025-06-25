-- SQL schema for clothing e-commerce (Shopee-like)
-- Drop old tables if exist
DROP TABLE IF EXISTS cart_items;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS product_reviews;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS product_variants;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS user_addresses;
DROP TABLE IF EXISTS users;

-- USERS
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) UNIQUE,
  email VARCHAR(100) UNIQUE,
  phone VARCHAR(20) UNIQUE,
  password VARCHAR(255) NOT NULL,
  gender ENUM('male','female','other') DEFAULT NULL,
  dob DATE DEFAULT NULL,
  role ENUM('user','admin') DEFAULT 'user',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- USER ADDRESSES
CREATE TABLE user_addresses (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  address_line VARCHAR(255) NOT NULL,
  city VARCHAR(100) NOT NULL,
  province VARCHAR(100) NOT NULL,
  postal_code VARCHAR(20),
  is_default BOOLEAN DEFAULT FALSE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- PRODUCTS
CREATE TABLE products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  category VARCHAR(100) NOT NULL,
  gender_target VARCHAR(20) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- PRODUCT VARIANTS
CREATE TABLE product_variants (
  id INT AUTO_INCREMENT PRIMARY KEY,
  color VARCHAR(50) NOT NULL,
  size VARCHAR(20) NOT NULL,
  material VARCHAR(50) NOT NULL,
  price DECIMAL(15,2) NOT NULL,
  stock INT NOT NULL DEFAULT 0,
  image_url VARCHAR(255),
  status ENUM('active','inactive','out_of_stock') DEFAULT 'active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- PRODUCT_PRODUCT_VARIANT
CREATE TABLE product_product_variant (
  product_id INT NOT NULL,
  product_variant_id INT NOT NULL,
  PRIMARY KEY (product_id, product_variant_id),
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
  FOREIGN KEY (product_variant_id) REFERENCES product_variants(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ORDERS
CREATE TABLE orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  address_id INT NOT NULL,
  order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  total_amount DECIMAL(15,2) NOT NULL,
  status ENUM('pending','confirmed','shipping','delivered','cancelled') DEFAULT 'pending',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (address_id) REFERENCES user_addresses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ORDER ITEMS
CREATE TABLE order_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  product_variant_id INT NOT NULL,
  quantity INT NOT NULL,
  price DECIMAL(15,2) NOT NULL, -- price at order time
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY (product_variant_id) REFERENCES product_variants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- PRODUCT REVIEWS
CREATE TABLE product_reviews (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  product_id INT NOT NULL,
  order_id INT NOT NULL,
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  content TEXT,
  image_url VARCHAR(255),
  video_url VARCHAR(255),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (product_id) REFERENCES products(id),
  FOREIGN KEY (order_id) REFERENCES orders(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- NOTIFICATIONS
CREATE TABLE notifications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  content TEXT,
  type ENUM('order_status','sale','voucher','other') DEFAULT 'other',
  is_read BOOLEAN DEFAULT FALSE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- PAYMENTS
CREATE TABLE payments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  payment_method ENUM('COD','Bank','Momo','VNPAY','Other') NOT NULL,
  amount DECIMAL(15,2) NOT NULL,
  status ENUM('pending','paid','failed','refunded') DEFAULT 'pending',
  transaction_code VARCHAR(100),
  paid_at DATETIME DEFAULT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- CART ITEMS
CREATE TABLE cart_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  product_variant_id INT NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  added_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (product_variant_id) REFERENCES product_variants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dữ liệu mẫu cho bảng products
INSERT INTO products (id, name, description, category, gender_target, created_at, updated_at)
VALUES
  (1, 'Áo thun nam basic', 'Áo thun cotton 100% cho nam, thoáng mát, dễ phối đồ.', 'Áo thun', 'Nam', NOW(), NOW()),
  (2, 'Quần jeans nữ skinny', 'Quần jeans co giãn, ôm dáng, phù hợp cho nữ.', 'Quần jeans', 'Nữ', NOW(), NOW()),
  (3, 'Áo khoác gió unisex', 'Áo khoác gió nhẹ, chống nước, phù hợp cả nam và nữ.', 'Áo khoác', 'Unisex', NOW(), NOW());

-- Dữ liệu mẫu cho bảng product_variants
INSERT INTO product_variants (id, color, size, material, price, stock, image_url, status)
VALUES
  (1, 'Trắng', 'M', 'Cotton', 150000, 50, 'https://example.com/images/ao-thun-trang-m.jpg', 'active'),
  (2, 'Đen', 'L', 'Cotton', 155000, 30, 'https://example.com/images/ao-thun-den-l.jpg', 'active'),
  (3, 'Xanh', 'S', 'Denim', 320000, 20, 'https://example.com/images/quan-jeans-xanh-s.jpg', 'active'),
  (4, 'Xanh', 'M', 'Denim', 320000, 15, 'https://example.com/images/quan-jeans-xanh-m.jpg', 'active'),
  (5, 'Đen', 'M', 'Polyester', 250000, 25, 'https://example.com/images/ao-khoac-den-m.jpg', 'active'),
  (6, 'Xám', 'L', 'Polyester', 255000, 10, 'https://example.com/images/ao-khoac-xam-l.jpg', 'active');

-- Dữ liệu mẫu cho bảng product_product_variant (liên kết sản phẩm và biến thể)
INSERT INTO product_product_variant (product_id, product_variant_id)
VALUES
  (1, 1),
  (1, 2),
  (2, 3),
  (2, 4),
  (3, 5),
  (3, 6);

-- Dữ liệu mẫu cho bảng users
INSERT INTO users (id, username, email, password, full_name, phone, address, created_at)
VALUES
  (1, 'nguyenvana', 'vana@example.com', 'hashed_password_1', 'Nguyễn Văn A', '0901234567', 'Hà Nội', NOW()),
  (2, 'lethib', 'lethib@example.com', 'hashed_password_2', 'Lê Thị B', '0912345678', 'TP.HCM', NOW());

-- Dữ liệu mẫu cho bảng orders
INSERT INTO orders (id, user_id, status, total_amount, created_at, updated_at)
VALUES
  (1, 1, 'pending', 305000, NOW(), NOW()),
  (2, 2, 'completed', 575000, NOW(), NOW());

-- Dữ liệu mẫu cho bảng order_items
INSERT INTO order_items (id, order_id, product_variant_id, quantity, price)
VALUES
  (1, 1, 1, 2, 150000),
  (2, 2, 3, 1, 320000),
  (3, 2, 5, 1, 250000);

-- Dữ liệu mẫu cho bảng cart_items
INSERT INTO cart_items (user_id, product_variant_id, quantity)
VALUES
  (1, 4, 1),
  (2, 2, 2);

-- Dữ liệu mẫu cho bảng product_reviews
INSERT INTO product_reviews (user_id, product_id, order_id, rating, content, image_url, video_url)
VALUES
  (1, 1, 1, 5, 'Áo rất đẹp, chất vải mát và mềm.', 'https://example.com/review/1.jpg', NULL),
  (2, 2, 2, 4, 'Quần jeans co giãn tốt, mặc vừa vặn.', NULL, NULL);

-- Dữ liệu mẫu cho bảng notifications
INSERT INTO notifications (user_id, title, content, type, is_read)
VALUES
  (1, 'Đơn hàng mới', 'Bạn vừa đặt đơn hàng #1 thành công.', 'order_status', FALSE),
  (2, 'Khuyến mãi', 'Nhận ngay voucher giảm giá 10% cho đơn hàng tiếp theo!', 'voucher', FALSE);

-- Dữ liệu mẫu cho bảng payments
INSERT INTO payments (order_id, payment_method, amount, status, transaction_code, paid_at)
VALUES
  (1, 'COD', 305000, 'pending', NULL, NULL),
  (2, 'Bank', 575000, 'paid', 'BANK123456', NOW());

