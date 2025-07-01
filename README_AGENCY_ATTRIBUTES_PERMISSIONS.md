# Agency Attributes & Values Permissions

## Tổng quan

Hệ thống đã được cập nhật để đảm bảo quyền quản lý thuộc tính và giá trị cho agency theo các yêu cầu sau:

## Yêu cầu chức năng

### 1. Thêm thuộc tính và giá trị
- ✅ Agency có thể thêm 1 hoặc nhiều thuộc tính
- ✅ Agency có thể thêm 1 hoặc nhiều giá trị cho bất kỳ thuộc tính nào

### 2. Xóa thuộc tính
- ✅ Agency A chỉ có thể xóa thuộc tính được tạo bởi chính Agency A đó
- ✅ Agency A không thể xóa thuộc tính được tạo bởi Admin hoặc Agency khác

### 3. Xóa giá trị thuộc tính
- ✅ Agency A chỉ có thể xóa giá trị được tạo bởi chính Agency A đó
- ✅ Agency A không thể xóa giá trị được tạo bởi Admin hoặc Agency khác

## Các thay đổi đã thực hiện

### Backend API Changes

#### 1. `delete_attribute.php`
- **Thay đổi**: Kiểm tra `created_by` trước khi xóa
- **Logic**: Chỉ cho phép xóa thuộc tính do agency hiện tại tạo
- **Bảo mật**: Thêm kiểm tra quyền sở hữu

#### 2. `delete_attribute_value.php`
- **Thay đổi**: Kiểm tra `created_by` trước khi xóa
- **Logic**: Chỉ cho phép xóa giá trị do agency hiện tại tạo
- **Bảo mật**: Thêm kiểm tra quyền sở hữu

#### 3. `get_attributes.php`
- **Thay đổi**: Thêm thông tin `created_by_name` cho attribute values
- **Mục đích**: Hiển thị ai đã tạo giá trị để UI có thể quyết định hiển thị nút xóa

### Frontend Changes

#### 1. `agency_attribute_manager_screen.dart`
- **Thay đổi**: Chỉ hiển thị nút xóa cho thuộc tính/giá trị do agency tạo
- **Logic**: Kiểm tra `created_by_name == 'agency'` để hiển thị nút xóa
- **UX**: Cải thiện trải nghiệm người dùng bằng cách ẩn các nút không có quyền

## Cấu trúc dữ liệu

### Attributes Table
```sql
CREATE TABLE attributes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id)
);
```

### Attribute Values Table
```sql
CREATE TABLE attribute_values (
    id INT PRIMARY KEY AUTO_INCREMENT,
    attribute_id INT NOT NULL,
    value VARCHAR(50) NOT NULL,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (attribute_id) REFERENCES attributes(id),
    FOREIGN KEY (created_by) REFERENCES users(id)
);
```

## API Endpoints

### GET `/agency/variants_attributes/get_attributes.php`
- **Mô tả**: Lấy danh sách thuộc tính và giá trị
- **Response**: Bao gồm thông tin `created_by_name` cho cả attributes và values

### POST `/agency/variants_attributes/add_attribute.php`
- **Mô tả**: Thêm thuộc tính mới
- **Quyền**: Agency có thể thêm thuộc tính

### POST `/agency/variants_attributes/add_attribute_value.php`
- **Mô tả**: Thêm giá trị thuộc tính
- **Quyền**: Agency có thể thêm giá trị cho bất kỳ thuộc tính nào

### DELETE `/agency/variants_attributes/delete_attribute.php`
- **Mô tả**: Xóa thuộc tính
- **Quyền**: Chỉ xóa được thuộc tính do agency hiện tại tạo

### DELETE `/agency/variants_attributes/delete_attribute_value.php`
- **Mô tả**: Xóa giá trị thuộc tính
- **Quyền**: Chỉ xóa được giá trị do agency hiện tại tạo

## Test Cases

File test: `API/tests/test_agency_attributes_permissions.php`

### Test Scenarios
1. ✅ Agency có thể thêm thuộc tính
2. ✅ Agency có thể thêm giá trị thuộc tính
3. ✅ Agency chỉ có thể xóa thuộc tính do mình tạo
4. ✅ Agency chỉ có thể xóa giá trị do mình tạo
5. ✅ Agency không thể xóa thuộc tính/giá trị do Admin tạo

## Bảo mật

### Kiểm tra quyền
- Tất cả API endpoints đều kiểm tra authentication
- Kiểm tra role 'agency' trước khi cho phép thao tác
- Kiểm tra quyền sở hữu trước khi xóa

### SQL Injection Protection
- Sử dụng prepared statements cho tất cả database queries
- Validate input data trước khi xử lý

### Error Handling
- Thông báo lỗi rõ ràng cho người dùng
- Log lỗi để debug và monitoring

## Deployment Notes

1. **Database**: Không cần thay đổi schema
2. **Backend**: Deploy các file PHP đã cập nhật
3. **Frontend**: Deploy Flutter app đã cập nhật
4. **Testing**: Chạy test file để verify functionality

## Monitoring

### Logs to Monitor
- Failed authentication attempts
- Unauthorized delete attempts
- Database errors

### Metrics to Track
- Number of attributes/values created per agency
- Delete operation success/failure rates
- API response times 