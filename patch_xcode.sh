#!/bin/bash

# Script để tự động chuyển đổi phiên bản Xcode (LastUpgradeCheck) cho project
# Dựa trên phiên bản Xcode đang cài đặt trên máy

# 1. Nhận đường dẫn project
if [ -z "$1" ]; then
    read -p "Vui lòng nhập đường dẫn đến thư mục project hoặc file .xcodeproj: " PROJECT_PATH
else
    PROJECT_PATH="$1"
fi

# Loại bỏ khoảng trắng hoặc nháy kép nếu người dùng kéo thả thư mục vào Terminal
PROJECT_PATH=$(echo "$PROJECT_PATH" | sed -e "s/^'//" -e "s/'$//" -e 's/^"//' -e 's/"$//')

if [ -z "$PROJECT_PATH" ] || [ ! -d "$PROJECT_PATH" ]; then
    echo "❌ Lỗi: Đường dẫn không hợp lệ hoặc thư mục không tồn tại!"
    exit 1
fi

# 2. Xác định file project.pbxproj
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

if [ ! -f "$PBXPROJ_PATH" ]; then
    echo "❌ Lỗi: Không tìm thấy file cấu hình tại $PBXPROJ_PATH"
    exit 1
fi

echo "🔍 Đang xử lý file: $PBXPROJ_PATH"

# 3. Lấy phiên bản Xcode hiện tại trên máy
XCODE_VERSION=$(xcodebuild -version | grep "Xcode" | awk '{print $2}')
if [ -z "$XCODE_VERSION" ]; then
    echo "❌ Lỗi: Không thể lấy được phiên bản Xcode. Đảm bảo bạn đã cài đặt Xcode và xcode-select."
    exit 1
fi
echo "✅ Phiên bản Xcode hiện tại trên máy: $XCODE_VERSION"

# 4. Chuyển đổi thành số mã hoá (LastUpgradeCheck) và các tham số khác
# Ví dụ: 13.4.1 -> Major: 13, Minor: 4 -> 1340
# Ví dụ: 15.0 -> Major: 15, Minor: 0 -> 1500
MAJOR=$(echo "$XCODE_VERSION" | cut -d. -f1)
MINOR=$(echo "$XCODE_VERSION" | cut -d. -f2)

if [ -z "$MINOR" ]; then
    MINOR="0"
fi

UPGRADE_CODE="${MAJOR}${MINOR}0"

# Xác định objectVersion dựa trên Major version
if [ "$MAJOR" -ge 15 ]; then
    OBJECT_VERSION="58"
elif [ "$MAJOR" -ge 14 ]; then
    OBJECT_VERSION="56"
elif [ "$MAJOR" -ge 13 ]; then
    OBJECT_VERSION="55"
elif [ "$MAJOR" -ge 12 ]; then
    OBJECT_VERSION="54"
else
    OBJECT_VERSION="53"
fi

COMPAT_VERSION="Xcode ${MAJOR}.0"

echo "✅ Mã định danh (LastUpgradeCheck) tương ứng: $UPGRADE_CODE"
echo "✅ Object Version: $OBJECT_VERSION"
echo "✅ Compatibility Version: $COMPAT_VERSION"

# 5. Cập nhật file project.pbxproj
# Sao lưu file gốc trước khi sửa
cp "$PBXPROJ_PATH" "${PBXPROJ_PATH}.bak"

# Dùng sed để thay thế giá trị LastUpgradeCheck (hỗ trợ trên macOS)
sed -i '' -E "s/LastUpgradeCheck = [0-9]{4,};/LastUpgradeCheck = $UPGRADE_CODE;/g" "$PBXPROJ_PATH"

# Cập nhật objectVersion
sed -i '' -E "s/objectVersion = [0-9]+;/objectVersion = $OBJECT_VERSION;/g" "$PBXPROJ_PATH"

# Cập nhật compatibilityVersion
sed -i '' -E "s/compatibilityVersion = \"Xcode [0-9]+\.[0-9]+\";/compatibilityVersion = \"$COMPAT_VERSION\";/g" "$PBXPROJ_PATH"

echo "🎉 Thành công! Đã chuyển đổi dự án để tương thích với Xcode $XCODE_VERSION (Mã: $UPGRADE_CODE)."
echo "💡 (File dự phòng đã được lưu tại: ${PBXPROJ_PATH}.bak)"
