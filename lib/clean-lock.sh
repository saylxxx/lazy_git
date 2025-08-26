#!/bin/bash

# 刪除 Git 鎖定檔案，解決 Git 操作被卡住的問題
# 使用方法: clean-lock [-f|--force]
# 預設會檢查是否有 Git 程序運行，使用 -f 可強制刪除
# 不論有沒有檔案都會試著去移除，顯示 '完成'

# 引用路徑處理器
source "$(dirname "$0")/path-helper.sh"

# 取得正確的 config.sh 路徑
CONFIG_PATH=$(get_config_path)

source "$CONFIG_PATH"
source "$(dirname "$0")/common.sh"

# 確保目錄存在
ensure_home_directory

# 檢查是否有 Git 程序正在運行
check_git_processes() {
    local git_pids=$(pgrep -f "git" 2>/dev/null)
    if [ -n "$git_pids" ]; then
        echo "警告：檢測到以下 Git 程序正在運行："
        ps aux | grep -E "(git|Git)" | grep -v grep | grep -v "clean-lock"
        return 1
    fi
    return 0
}

# 刪除 Git 鎖定檔案
clean_lock() {
    local force_mode=false
    
    # 處理參數
    if [ "$1" = "-f" ] || [ "$1" = "--force" ]; then
        force_mode=true
        echo "強制模式：將忽略運行中的 Git 程序"
    fi
    
    # 檢查 Git 程序（除非是強制模式）
    if [ "$force_mode" = false ]; then
        if ! check_git_processes; then
            echo ""
            echo "建議："
            echo "1. 等待 Git 操作完成"
            echo "2. 手動終止相關程序"
            echo "3. 使用 clean-lock -f 強制刪除鎖定檔案"
            echo ""
            read -p "是否仍要繼續刪除鎖定檔案？(y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "操作已取消"
                exit 0
            fi
        fi
    fi

    local lock_files=(
        ".git/ORIG_HEAD.lock"
        ".git/index.lock"
        ".git/HEAD.lock"
        ".git/config.lock"
        ".git/packed-refs.lock"
    )
    
    # 新增：動態查找其他鎖定檔案
    local additional_locks=$(find .git -name "*.lock" 2>/dev/null)
    
    local deleted_count=0
    local not_found_count=0

    echo "開始清理 Git 鎖定檔案..."
    echo "=============================="

    for lock_file in "${lock_files[@]}"; do
        if [ -e "$lock_file" ]; then
            rm -f "$lock_file"
            echo "✓ 已刪除: $lock_file"
            ((deleted_count++))
        else
            echo "- 未找到: $lock_file"
            ((not_found_count++))
        fi
    done
    
    # 處理動態找到的其他鎖定檔案
    if [ -n "$additional_locks" ]; then
        echo ""
        echo "發現額外的鎖定檔案："
        echo "$additional_locks" | while read -r lock_file; do
            if [ -n "$lock_file" ] && [ -e "$lock_file" ]; then
                # 檢查是否已經在上面的列表中處理過
                local already_processed=false
                for processed_file in "${lock_files[@]}"; do
                    if [ "$lock_file" = "$processed_file" ]; then
                        already_processed=true
                        break
                    fi
                done
                
                if [ "$already_processed" = false ]; then
                    rm -f "$lock_file"
                    echo "✓ 已刪除額外檔案: $lock_file"
                    ((deleted_count++))
                fi
            fi
        done
    fi

    echo "=============================="
    echo "總結："
    echo "- 已刪除檔案: $deleted_count 個"
    echo "- 未找到檔案: $not_found_count 個"
    echo "完成"
}

clean_lock "$@"