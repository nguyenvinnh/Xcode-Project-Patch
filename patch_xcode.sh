#!/bin/bash

# Script để tự động chuyển đổi phiên bản Xcode (LastUpgradeCheck) cho nhiều project trong 1 thư mục

# Tiền xử lý: Tách các đường dẫn bị dính liền do shell gộp chuỗi (ví dụ: /Users/a/Users/b)
NEW_ARGS=""
for arg in "$@"; do
    if [[ "$arg" == *"/Users/"* ]]; then
        arg=$(echo "$arg" | sed 's#/Users/# /Users/#g')
    fi
    NEW_ARGS="$NEW_ARGS $arg"
done
eval "set -- $NEW_ARGS"

# 1. Nhận đường dẫn
if [ $# -eq 0 ]; then
    read -p "Vui lòng nhập đường dẫn đến thư mục chứa các project: " RAW_INPUT
    # Chuẩn hóa nếu người dùng copy paste nhiều đường dẫn dính nhau kiểu '/a''/b' hoặc "/a""/b"
    RAW_INPUT=$(echo "$RAW_INPUT" | sed -e "s/''/' '/g" -e 's/""/" "/g')
    eval "set -- $RAW_INPUT"
fi

if [ $# -eq 0 ]; then
    echo "Lỗi: Bạn chưa nhập đường dẫn nào!"
    exit 1
fi

# 2. Lấy phiên bản Xcode hiện tại trên máy
XCODE_VERSION=$(xcodebuild -version | grep "Xcode" | awk '{print $2}')
if [ -z "$XCODE_VERSION" ]; then
    echo "Lỗi: Không thể lấy được phiên bản Xcode. Đảm bảo bạn đã cài đặt Xcode."
    exit 1
fi

MAJOR=$(echo "$XCODE_VERSION" | cut -d. -f1)
MINOR=$(echo "$XCODE_VERSION" | cut -d. -f2)
if [ -z "$MINOR" ]; then MINOR="0"; fi

UPGRADE_CODE="${MAJOR}${MINOR}0"

# Xác định objectVersion lớn nhất mà Xcode hiện tại hỗ trợ
if [ "$MAJOR" -ge 15 ]; then OBJECT_VERSION="58"
elif [ "$MAJOR" -ge 14 ]; then OBJECT_VERSION="56"
elif [ "$MAJOR" -ge 13 ]; then OBJECT_VERSION="55"
elif [ "$MAJOR" -ge 12 ]; then OBJECT_VERSION="54"
else OBJECT_VERSION="53"
fi

COMPAT_VERSION="Xcode ${MAJOR}.0"

echo "Phiên bản Xcode hiện tại: $XCODE_VERSION (ObjectVersion hỗ trợ: <= $OBJECT_VERSION)"
echo "---------------------------------------------------"

# 3. Lặp qua tất cả các đường dẫn cung cấp
for ROOT_PATH in "$@"; do
    ROOT_PATH=$(echo "$ROOT_PATH" | sed -e "s/^'//" -e "s/'$//" -e 's/^"//' -e 's/"$//')
    
    if [ -z "$ROOT_PATH" ] || [ ! -d "$ROOT_PATH" ]; then
        # Chỉ báo lỗi nếu chuỗi nhập vào giống như 1 đường dẫn (có chứa dấu /)
        # Nếu là các từ ngẫu nhiên (ví dụ copy nhầm prompt) thì sẽ bỏ qua trong im lặng
        if [[ "$ROOT_PATH" == *"/"* ]]; then
            echo "Lỗi: Đường dẫn không hợp lệ hoặc thư mục không tồn tại: $ROOT_PATH"
            echo "---------------------------------------------------"
        fi
        continue
    fi
    
    echo "ĐANG QUÉT THƯ MỤC: $ROOT_PATH"

    # Tìm tất cả các file .xcodeproj trong thư mục
    FIND_OUTPUT=$(find "$ROOT_PATH" -type d -name "*.xcodeproj" -exec dirname {} \;)
    if [ -z "$FIND_OUTPUT" ]; then
        echo "Không tìm thấy project Xcode nào trong thư mục này."
        echo "---------------------------------------------------"
        continue
    fi

    # Loại bỏ các dòng trùng lặp (nếu có nhiều file .xcodeproj trong cùng 1 thư mục cha)
    UNIQUE_DIRS=$(echo "$FIND_OUTPUT" | sort | uniq -c)

    echo "$UNIQUE_DIRS" | while read -r count dir; do
        if [ "$count" -gt 1 ]; then
            echo "BỎ QUA: Thư mục '$dir' có chứa $count file .xcodeproj (nhiều hơn 1 file ở cùng vị trí). Không an toàn để xử lý!"
            echo "---------------------------------------------------"
            continue
        fi
        
        # Lấy đường dẫn file pbxproj
        XCODEPROJ_DIR=$(find "$dir" -maxdepth 1 -type d -name "*.xcodeproj" | head -n 1)
        PBXPROJ_PATH="$XCODEPROJ_DIR/project.pbxproj"
        
        if [ ! -f "$PBXPROJ_PATH" ]; then
            continue
        fi
        
        # Kiểm tra objectVersion của project
        CURRENT_OBJ_VER=$(grep -oE "objectVersion = [0-9]+" "$PBXPROJ_PATH" | head -n 1 | awk '{print $3}')
        
        if [ -n "$CURRENT_OBJ_VER" ] && [ "$CURRENT_OBJ_VER" -le "$OBJECT_VERSION" ]; then
            echo "BỎ QUA: '$XCODEPROJ_DIR' - Project này (objectVersion: $CURRENT_OBJ_VER) đã đủ điều kiện chạy trên Xcode $XCODE_VERSION."
            echo "---------------------------------------------------"
            continue
        fi
        
        echo "ĐANG XỬ LÝ: '$XCODEPROJ_DIR'"
        echo "   - Cập nhật objectVersion ($CURRENT_OBJ_VER -> $OBJECT_VERSION)"
        
        # Sao lưu file gốc trước khi sửa
        cp "$PBXPROJ_PATH" "${PBXPROJ_PATH}.bak"

        # Thay đổi các thông số
        sed -i '' -E "s/LastUpgradeCheck = [0-9]{4,};/LastUpgradeCheck = $UPGRADE_CODE;/g" "$PBXPROJ_PATH"
        sed -i '' -E "s/objectVersion = [0-9]+;/objectVersion = $OBJECT_VERSION;/g" "$PBXPROJ_PATH"
        sed -i '' -E "s/compatibilityVersion = \"Xcode [0-9]+\.[0-9]+\";/compatibilityVersion = \"$COMPAT_VERSION\";/g" "$PBXPROJ_PATH"
        
        echo " Hoàn tất vá lỗi dự án này!"
        echo "---------------------------------------------------"
    done
done

echo "TẤT CẢ HOÀN TẤT!"
