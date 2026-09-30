#!/bin/bash

# Script để khôi phục cấu hình dự án Xcode từ file backup (.bak) hàng loạt

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
    read -p "Vui lòng nhập đường dẫn đến thư mục chứa các project để khôi phục: " RAW_INPUT
    # Chuẩn hóa nếu người dùng copy paste nhiều đường dẫn dính nhau kiểu '/a''/b' hoặc "/a""/b"
    RAW_INPUT=$(echo "$RAW_INPUT" | sed -e "s/''/' '/g" -e 's/""/" "/g')
    eval "set -- $RAW_INPUT"
fi

if [ $# -eq 0 ]; then
    echo "Lỗi: Bạn chưa nhập đường dẫn nào!"
    exit 1
fi

echo "Đang quét để khôi phục file cấu hình gốc..."
echo "---------------------------------------------------"

# 2. Lặp qua tất cả các đường dẫn cung cấp
for ROOT_PATH in "$@"; do
    ROOT_PATH=$(echo "$ROOT_PATH" | sed -e "s/^'//" -e "s/'$//" -e 's/^"//' -e 's/"$//')
    
    if [ -z "$ROOT_PATH" ] || [ ! -d "$ROOT_PATH" ]; then
        # Chỉ báo lỗi nếu chuỗi nhập vào giống như 1 đường dẫn (có chứa dấu /)
        if [[ "$ROOT_PATH" == *"/"* ]]; then
            echo "Lỗi: Đường dẫn không hợp lệ hoặc thư mục không tồn tại: $ROOT_PATH"
            echo "---------------------------------------------------"
        fi
        continue
    fi

    echo "🔎 ĐANG QUÉT THƯ MỤC: $ROOT_PATH"

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
            echo "BỎ QUA: Thư mục '$dir' có chứa $count file .xcodeproj. Bỏ qua để đảm bảo an toàn."
            echo "---------------------------------------------------"
            continue
        fi
        
        # Lấy đường dẫn file pbxproj
        XCODEPROJ_DIR=$(find "$dir" -maxdepth 1 -type d -name "*.xcodeproj" | head -n 1)
        PBXPROJ_PATH="$XCODEPROJ_DIR/project.pbxproj"
        BACKUP_PATH="${PBXPROJ_PATH}.bak"
        
        if [ ! -f "$BACKUP_PATH" ]; then
            echo "BỎ QUA: '$XCODEPROJ_DIR' - Không tìm thấy file backup (.bak) nào tại đây."
            echo "---------------------------------------------------"
            continue
        fi
        
        echo "ĐANG KHÔI PHỤC: '$XCODEPROJ_DIR'"
        cp "$BACKUP_PATH" "$PBXPROJ_PATH"
        
        if [ $? -eq 0 ]; then
            echo "   Khôi phục thành công cấu trúc ban đầu!"
            # Tự động xóa file backup cho sạch sẽ sau khi khôi phục thành công
            rm "$BACKUP_PATH"
            echo "   Đã dọn dẹp file dự phòng."
        else
            echo "   Lỗi: Không thể khôi phục được file này."
        fi
        echo "---------------------------------------------------"
    done
done

echo "TẤT CẢ HOÀN TẤT!"
