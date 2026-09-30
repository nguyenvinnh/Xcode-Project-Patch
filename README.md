# Xcode Project Patch

Đoạn code này cung cấp các script (bash) giúp giải quyết lỗi "cannot be opened because it is in a future Xcode project file format" khi mở các dự án Xcode mới trên phiên bản Xcode cũ hơn.

## Các chức năng chính
- Code có khả năng quét và xử lý (hoặc khôi phục) 1 hoặc nhiều project cùng một lúc. Nó sẽ tự động lọc và bỏ qua các project đã đủ điều kiện tương thích.
- **`patch_xcode.sh`**: Tự động nhận diện phiên bản Xcode hiện tại trên máy, sau đó chuyển đổi cấu trúc file project (`LastUpgradeCheck`, `objectVersion`, `compatibilityVersion`) để tương thích. Script tự động tạo bản sao lưu (`.bak`) trước khi sửa.
- **`restore_xcode.sh`**: Khôi phục lại cấu hình gốc của project bằng file dự phòng `.bak`.

## Cách sử dụng

Mở ứng dụng Terminal, di chuyển tới thư mục chứa các script và chạy các lệnh dưới đây. 
*(Mẹo: Bạn có thể bỏ trống đường dẫn project lúc gọi lệnh, script sẽ dừng lại và yêu cầu bạn kéo thả thư mục project vào)*

### 1. Sửa dự án (Patch)
```bash
./patch_xcode.sh /đường/dẫn/đến/project_ios_của_bạn
```

### 2. Khôi phục dự án (Restore)
```bash
./restore_xcode.sh /đường/dẫn/đến/project_ios_của_bạn
```

