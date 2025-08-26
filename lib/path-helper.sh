#!/bin/bash

# 智能路徑檢測 - 用於 config.sh 的引用
# 這個腳本會檢測 config.sh 的正確位置

get_config_path() {
    local script_dir="$(dirname "$0")"
    
    # 檢查開發環境路徑（在 lib/ 子目錄中）
    if [ -f "$script_dir/../config.sh" ]; then
        echo "$script_dir/../config.sh"
        return 0
    fi
    
    # 檢查安裝環境路徑（同一目錄）
    if [ -f "$script_dir/config.sh" ]; then
        echo "$script_dir/config.sh"
        return 0
    fi
    
    # 檢查當前目錄
    if [ -f "./config.sh" ]; then
        echo "./config.sh"
        return 0
    fi
    
    # 檢查絕對路徑（可能在 git-lib 目錄）
    if [ -f "$script_dir/../../config.sh" ]; then
        echo "$script_dir/../../config.sh"
        return 0
    fi
    
    # 如果都找不到，回傳開發環境的預設路徑
    echo "$script_dir/../config.sh"
    return 1
}

# 導出函數供其他腳本使用
export -f get_config_path
