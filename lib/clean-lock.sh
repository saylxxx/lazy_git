#!/bin/bash

# 刪除 .git/ORIG_HEAD.lock, .git/index.lock, 和其他鎖定檔案
# 使用方法: clean-lock
# 不論有沒有檔案都會試著去移除，顯示 '完成'

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/common.sh"

# 確保目錄存在
ensure_home_directory

# 刪除 .git/ORIG_HEAD.lock, .git/index.lock, 和其他鎖定檔案
clean_lock() {
    local lock_files=(
        ".git/ORIG_HEAD.lock"
        ".git/index.lock"
        ".git/HEAD.lock"
        # ".git/refs/heads/*.lock"
        # ".git/refs/tags/*.lock"
    )

    for lock_file in "${lock_files[@]}"; do
        if [ -e "$lock_file" ]; then
            rm -f "$lock_file"
            echo "已刪除鎖定檔案: $lock_file"
        else
            echo "未找到鎖定檔案: $lock_file"
        fi
    done

    echo "完成"
}

clean_lock