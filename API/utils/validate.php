<?php
// Kiểm tra định dạng email hợp lệ
function isValidEmail($email) {
    return filter_var($email, FILTER_VALIDATE_EMAIL);
}

// Kiểm tra định dạng số điện thoại Việt Nam (bắt đầu bằng 0, 10 số)
function isValidPhone($phone) {
    return preg_match('/^0[0-9]{9}$/', $phone);
}

// Kiểm tra độ dài mật khẩu tối thiểu 6 ký tự
function isValidPassword($password) {
    return strlen($password) >= 6;
}

// Kiểm tra giá trị giới tính hợp lệ ('male', 'female', 'other')
function isValidGender($gender) {
    return in_array($gender, ['male', 'female', 'other']);
}

// Kiểm tra giá trị vai trò hợp lệ ('user', 'admin')
function isValidRole($role) {
    return in_array($role, ['user', 'admin']);
}

// Kiểm tra định dạng ngày/tháng/năm và không phải ngày tương lai
function isValidDate($date) {
    $d = DateTime::createFromFormat('Y-m-d', $date);
    return $d && $d->format('Y-m-d') === $date && strtotime($date) <= time();
}

// Kiểm tra giá trị không rỗng
function isNotEmpty($value) {
    return !empty($value);
}

// Kiểm tra giá trị boolean (true/false, 0/1)
function isBoolean($value) {
    return is_bool($value) || $value === 0 || $value === 1 || $value === '0' || $value === '1';
}

// Kiểm tra danh mục sản phẩm hợp lệ
function isValidCategory($category) {
    $categories = ['T-Shirts','Shirts','Jackets & Coats','Pants','Shorts','Knitwear','Suits & Blazers','Hoodies','Underwear','Loungewear'];
    return in_array($category, $categories);
}

// Kiểm tra trường giới tính hướng tới hợp lệ
function isValidGenderTarget($gender_target) {
    return in_array($gender_target, ['male','female','kids','unisex']);
}

// Kiểm tra màu sắc hợp lệ
function isValidColor($color) {
    $colors = ['white','black','purple','pink','blue','silver','red','yellow','green','brown','gray','orange'];
    return in_array($color, $colors);
}

// Kiểm tra kích cỡ hợp lệ
function isValidSize($size) {
    $sizes = ['S','M','L','XL','XXL','XXXL'];
    return in_array($size, $sizes);
}

// Kiểm tra chất liệu hợp lệ
function isValidMaterial($material) {
    $materials = ['Cotton','Linen','Wool','Polyester','Denim','Leather','Silk','Nylon'];
    return in_array($material, $materials);
}

// Kiểm tra kiểu dáng hợp lệ
function isValidStyle($style) {
    $styles = ['T-Shirts','Shirts','Jackets & Coats','Pants','Shorts','Knitwear','Suits & Blazers','Hoodies','Underwear','Loungewear'];
    return in_array($style, $styles);
}

// Kiểm tra số dương (giá, tồn kho...)
function isPositiveNumber($number) {
    return is_numeric($number) && $number > 0;
}

// Kiểm tra số nguyên dương (số lượng, tồn kho...)
function isPositiveInteger($number) {
    return is_numeric($number) && intval($number) == $number && $number > 0;
}

// Kiểm tra trạng thái biến thể sản phẩm hợp lệ
function isValidStatus($status) {
    return in_array($status, ['active','inactive','out_of_stock']);
}

// Kiểm tra trạng thái đơn hàng hợp lệ
function isValidOrderStatus($status) {
    return in_array($status, ['pending','confirmed','shipping','delivered','cancelled']);
}

// Kiểm tra số tiền >= 0
function isPositiveAmount($amount) {
    return is_numeric($amount) && $amount >= 0;
}

// Kiểm tra số sao đánh giá hợp lệ (1-5)
function isValidRating($rating) {
    return is_numeric($rating) && $rating >= 1 && $rating <= 5;
}

// Kiểm tra định dạng URL (ảnh, video)
function isValidUrl($url) {
    return filter_var($url, FILTER_VALIDATE_URL);
}

// Kiểm tra loại thông báo hợp lệ
function isValidNotificationType($type) {
    return in_array($type, ['order_status','sale','voucher','other']);
}

// Kiểm tra phương thức thanh toán hợp lệ
function isValidPaymentMethod($method) {
    return in_array($method, ['COD','Bank','Momo','VNPAY','Other']);
}

// Kiểm tra trạng thái thanh toán hợp lệ
function isValidPaymentStatus($status) {
    return in_array($status, ['pending','paid','failed','refunded']);
}

// Kiểm tra mã bưu điện hợp lệ (có thể mở rộng theo quy tắc từng vùng)
function isValidPostalCode($postal_code) {
    return preg_match('/^[0-9]{5,6}$/', $postal_code);
}
?>

