-- SQL schema for clothing e-commerce (Shopee-like)
-- Create database
DROP DATABASE IF EXISTS clothing_appstore;
CREATE DATABASE IF NOT EXISTS clothing_appstore;
USE clothing_appstore;

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

-- ATTRIBUTES (color, size, brand, ...)
CREATE TABLE attributes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ATTRIBUTE VALUES (red, blue, S, M, Nike, Adidas, ...)
CREATE TABLE attribute_values (
  id INT AUTO_INCREMENT PRIMARY KEY,
  attribute_id INT NOT NULL,
  value VARCHAR(50) NOT NULL,
  FOREIGN KEY (attribute_id) REFERENCES attributes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- VARIANTS (mỗi variant là 1 tổ hợp giá trị thuộc tính, có SKU)
CREATE TABLE variants (
  id INT AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- VARIANT_ATTRIBUTE_VALUES (liên kết variant với các giá trị thuộc tính)
CREATE TABLE variant_attribute_values (
  variant_id INT NOT NULL,
  attribute_value_id INT NOT NULL,
  PRIMARY KEY (variant_id, attribute_value_id),
  FOREIGN KEY (variant_id) REFERENCES variants(id) ON DELETE CASCADE,
  FOREIGN KEY (attribute_value_id) REFERENCES attribute_values(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- PRODUCT_VARIANT (liên kết product với variant, có giá và tồn kho riêng)
CREATE TABLE product_variant (
  product_id INT NOT NULL,
  variant_id INT NOT NULL,
  price DECIMAL(15,2) NOT NULL,
  stock INT NOT NULL DEFAULT 0,
  image_url VARCHAR(255),
  status ENUM('active','inactive','out_of_stock') DEFAULT 'active',
  PRIMARY KEY (product_id, variant_id),
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
  FOREIGN KEY (variant_id) REFERENCES variants(id) ON DELETE CASCADE
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
  product_id INT NOT NULL,
  variant_id INT NOT NULL,
  quantity INT NOT NULL,
  price DECIMAL(15,2) NOT NULL, -- price at order time
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id, variant_id) REFERENCES product_variant(product_id, variant_id)
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
  product_id INT NOT NULL,
  variant_id INT NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  added_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id, variant_id) REFERENCES product_variant(product_id, variant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO users (username, email, phone, password, gender, dob, role)
VALUES 
('alice123', 'alice@example.com', '0909000001', 'hashed_pass_1', 'female', '1995-06-01', 'user'),
('bobshop', 'bob@example.com', '0909000002', 'hashed_pass_2', 'male', '1990-01-15', 'admin');

INSERT INTO user_addresses (user_id, address_line, city, province, postal_code, is_default)
VALUES
(1, '123 Lê Lợi', 'Hà Nội', 'Hà Nội', '100000', TRUE),
(2, '456 Nguyễn Huệ', 'TP.HCM', 'Hồ Chí Minh', '700000', TRUE);

INSERT INTO products (name, description, category, gender_target)
VALUES
('Áo thun basic', 'Áo thun cotton thoáng mát', 'T-Shirts', 'unisex'),
('Quần jeans slim fit', 'Chất liệu denim cao cấp', 'Pants', 'male');

INSERT INTO attributes (name) VALUES
('color'),
('size'),
('brand');

INSERT INTO attribute_values (attribute_id, value) VALUES
(1, 'white'),
(1, 'black'),
(1, 'blue'),
(2, 'M'),
(2, 'L'),
(2, 'XL'),
(3, 'Nike'),
(3, 'Adidas');

INSERT INTO variants (sku) VALUES
('TSHIRT-WHITE-M-NIKE'),
('TSHIRT-BLACK-L-ADIDAS'),
('JEANS-BLUE-XL-NIKE');

INSERT INTO variant_attribute_values (variant_id, attribute_value_id) VALUES
(1, 1),
(1, 4),
(1, 7);

INSERT INTO variant_attribute_values (variant_id, attribute_value_id) VALUES
(2, 2),
(2, 5),
(2, 8);

INSERT INTO variant_attribute_values (variant_id, attribute_value_id) VALUES
(3, 3),
(3, 6),
(3, 7);

INSERT INTO product_variant (product_id, variant_id, price, stock, image_url, status) VALUES
(1, 1, 150000, 100, 'url_image1.jpg', 'active'),
(1, 2, 155000, 80, 'url_image2.jpg', 'active'),
(2, 3, 350000, 50, 'url_image3.jpg', 'active');

INSERT INTO orders (user_id, address_id, total_amount, status)
VALUES
(1, 1, 150000, 'confirmed'),
(2, 2, 350000, 'shipping');

INSERT INTO order_items (order_id, product_id, variant_id, quantity, price) VALUES
(1, 1, 1, 1, 150000), -- Đơn hàng 1: Áo thun basic - trắng M Nike
(1, 1, 2, 2, 155000), -- Đơn hàng 1: Áo thun basic - đen L Adidas
(2, 2, 3, 1, 350000); -- Đơn hàng 2: Quần jeans slim fit - xanh XL Nike

INSERT INTO product_reviews (user_id, product_id, order_id, rating, content, image_url)
VALUES
(1, 1, 1, 5, 'Áo đẹp, thoải mái', 'review_img1.jpg'),
(2, 2, 2, 4, 'Quần ôm dáng, đẹp', 'review_img2.jpg');

INSERT INTO notifications (user_id, title, content, type)
VALUES
(1, 'Đơn hàng đã xác nhận', 'Đơn hàng của bạn đang được xử lý', 'order_status'),
(2, 'Ưu đãi cuối tuần', 'Giảm giá 10% cho mọi đơn hàng', 'sale');

INSERT INTO payments (order_id, payment_method, amount, status, transaction_code, paid_at)
VALUES
(1, 'Momo', 150000, 'paid', 'MOMO123456', NOW()),
(2, 'COD', 350000, 'pending', NULL, NULL);

INSERT INTO cart_items (user_id, product_id, variant_id, quantity) VALUES
(1, 2, 3, 1), -- User 1 thêm Quần jeans slim fit - xanh XL Nike vào giỏ
(2, 1, 1, 2); -- User 2 thêm Áo thun basic - trắng M Nike vào giỏ
