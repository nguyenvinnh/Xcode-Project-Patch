#!/bin/bash

# Script để khôi phục cấu hình dự án Xcode từ file backup (.bak)

# 1. Nhận đường dẫn project
if [ -z "$1" ]; then
    read -p "Vui lòng nhập đường dẫn đến thư mục project hoặc file .xcodeproj để khôi phục: " PROJECT_PATH
else
    PROJECT_PATH="$1"
fi

# Loại bỏ khoảng trắng hoặc nháy kép nếu người dùng kéo thả thư mục vào Terminal
PROJECT_PATH=$(echo "$PROJECT_PATH" | sed -e "s/^'//" -e "s/'$//" -e 's/^"//' -e 's/"$//')

if [ -z "$PROJECT_PATH" ] || [ ! -d "$PROJECT_PATH" ]; then
    echo "❌ Lỗi: Đường dẫn không hợp lệ hoặc thư mục không tồn tại!"
    exit 1
fi

# 2. Xác định file project.pbxproj và file backup
if [[ "$PROJECT_PATH" == *.xcodeproj ]]; then
    PBXPROJ_PATH="$PROJECT_PATH/project.pbxproj"
else
    # Tìm thư mục .xcodeproj trong đường dẫn cung cấp
    XCODEPROJ_DIR=$(find "$PROJECT_PATH" -maxdepth 1 -name "*.xcodeproj" | head -n 1)
    if [ -z "$XCODEPROJ_DIR" ]; then
        echo "❌ Lỗi: Không tìm thấy file .xcodeproj nào trong thư mục $PROJECT_PATH"
        exit 1
    fi
    PBXPROJ_PATH="$XCODEPROJ_DIR/project.pbxproj"
fi

BACKUP_PATH="${PBXPROJ_PATH}.bak"

if [ ! -f "$BACKUP_PATH" ]; then
    echo "❌ Lỗi: Không tìm thấy file dự phòng (backup) tại $BACKUP_PATH."
    echo "Có vẻ như dự án này chưa từng được chỉnh sửa bởi script hoặc file backup đã bị xóa."
    exit 1
fi

# 3. Tiến hành khôi phục
echo "🔄 Đang khôi phục file cấu hình gốc..."
cp "$BACKUP_PATH" "$PBXPROJ_PATH"

if [ $? -eq 0 ]; then
    echo "🎉 Khôi phục thành công! Dự án đã trở về trạng thái cấu trúc ban đầu."
    
    # Tùy chọn xóa file backup
    read -p "Bạn có muốn xóa file dự phòng (.bak) này cho sạch sẽ không? (y/n): " DELETE_BAK
    if [[ "$DELETE_BAK" == "y" || "$DELETE_BAK" == "Y" ]]; then
        rm "$BACKUP_PATH"
        echo "✅ Đã xóa file backup."
    fi
else
    echo "❌ Lỗi: Không thể khôi phục được file."
    exit 1
fi
