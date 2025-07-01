# Agency Product Status Update Summary

## Overview
Đã cập nhật trạng thái sản phẩm do agency tạo từ `draft` thành `inactive` trước khi gửi duyệt.

## Changes Made

### 1. Backend API Changes

#### **File: `API/agency/products/add_product.php`**
- ✅ Thay đổi trạng thái sản phẩm từ `'draft'` thành `'inactive'`
- ✅ Thay đổi trạng thái approval từ `'draft'` thành `'inactive'`
- ✅ Cập nhật response message để phản ánh trạng thái mới

#### **File: `API/agency/submit_for_approval.php`**
- ✅ Cập nhật validation để chấp nhận trạng thái `'inactive'` thay vì `'draft'`
- ✅ Cập nhật error message để phản ánh trạng thái mới

### 2. Frontend Model Changes

#### **File: `userfe/lib/models/agency_product_model.dart`**
- ✅ Thay đổi `isDraft` thành `isInactive`
- ✅ Cập nhật `canEdit`, `canSubmit`, `canDelete` để sử dụng `isInactive`
- ✅ Cập nhật `statusDisplay` để hiển thị "Không hoạt động" cho trạng thái `inactive`
- ✅ Cập nhật `approvalStatusDisplay` để xử lý trạng thái `inactive`

### 3. Frontend UI Changes

#### **File: `userfe/lib/screens/agency/agency_product_screen.dart`**
- ✅ Cập nhật comment để phản ánh trạng thái mới
- ✅ Cập nhật error message để hiển thị "không hoạt động" thay vì "nháp"
- ✅ Thêm màu sắc cho trạng thái `approved` (màu xanh dương)

## Product Status Flow

### **Trước khi gửi duyệt:**
1. **Agency tạo sản phẩm** → Trạng thái: `inactive`
2. **Agency thêm biến thể** → Sản phẩm vẫn `inactive`
3. **Nút gửi duyệt xuất hiện** → Khi đủ điều kiện và trạng thái `inactive`

### **Sau khi gửi duyệt:**
1. **Agency nhấn gửi duyệt** → Trạng thái chuyển thành `pending`
2. **Admin duyệt** → Trạng thái chuyển thành `approved` hoặc `rejected`
3. **Nếu bị từ chối** → Trạng thái `rejected`, có thể gửi lại

## Status Meanings

| Trạng thái | Ý nghĩa | Màu sắc | Có thể gửi duyệt |
|------------|---------|---------|------------------|
| `inactive` | Không hoạt động | Xám | ✅ |
| `pending` | Chờ duyệt | Cam | ❌ |
| `approved` | Đã duyệt | Xanh dương | ❌ |
| `rejected` | Từ chối | Đỏ | ✅ |

## Validation Logic

### **Sản phẩm có thể gửi duyệt khi:**
- ✅ Trạng thái là `inactive` hoặc `rejected`
- ✅ Có đầy đủ thông tin (tên, danh mục, đối tượng, hình ảnh)
- ✅ Có ít nhất 1 biến thể hợp lệ
- ✅ Tất cả biến thể có đủ thông tin (SKU, giá, tồn kho, thuộc tính)

### **Sản phẩm KHÔNG thể gửi duyệt khi:**
- ❌ Trạng thái là `pending` (đang chờ duyệt)
- ❌ Trạng thái là `approved` (đã được duyệt)
- ❌ Thiếu thông tin cần thiết
- ❌ Không có biến thể hợp lệ

## Benefits

### **1. Rõ ràng hơn:**
- Trạng thái `inactive` rõ ràng hơn `draft`
- Phản ánh đúng trạng thái sản phẩm chưa được kích hoạt

### **2. Consistent với business logic:**
- Sản phẩm chưa được duyệt = không hoạt động
- Chỉ khi được admin duyệt mới trở thành active

### **3. Better UX:**
- User hiểu rõ trạng thái sản phẩm
- Màu sắc và text phù hợp với trạng thái

## Testing Scenarios

### ✅ **Valid Cases:**
- Tạo sản phẩm mới → Trạng thái `inactive`
- Gửi duyệt từ `inactive` → Thành công
- Gửi lại từ `rejected` → Thành công

### ❌ **Invalid Cases:**
- Gửi duyệt từ `pending` → Lỗi
- Gửi duyệt từ `approved` → Lỗi

## Result
✅ **Trạng thái sản phẩm đã được cập nhật thành công!**

- Sản phẩm mới tạo có trạng thái `inactive`
- Logic validation và UI đã được cập nhật
- User experience được cải thiện với trạng thái rõ ràng hơn 