#!/bin/bash

# 刪除所有本地分支，排除配置的主分支和開發分支
# 使用方法: clean-ab [-f|--force]
# 預設會顯示要刪除的分支並要求確認，使用 -f 可強制刪除
# 如果沒有本地分支，顯示 '完成'

# 引用路徑處理器
source "$(dirname "$0")/path-helper.sh"

# 取得正確的 config.sh 路徑
CONFIG_PATH=$(get_config_path)

source "$CONFIG_PATH"
source "$(dirname "$0")/common.sh"

# 確保目錄存在
ensure_home_directory

# 刪除所有本地分支，排除配置的主分支和開發分支
clean_ab_branches() {
    local force_mode=false
    
    # 處理參數
    if [ "$1" = "-f" ] || [ "$1" = "--force" ]; then
        force_mode=true
        echo "強制模式：將直接刪除所有符合條件的分支"
    fi
    
    branches=$(git branch | grep -v '\*')
    for branch in $LAZYGIT_EXCLUDED_BRANCHES; do
        branches=$(echo "$branches" | grep -v "$branch")
    done

    if [ -z "$branches" ]; then
        echo '完成'
        return 0
    fi
    
    # 清理分支名稱中的空白字符
    branches=$(echo "$branches" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    
    if [ "$force_mode" = false ]; then
        echo "即將刪除以下分支："
        echo "$branches" | while read -r branch; do
            if [ -n "$branch" ]; then
                echo "  - $branch"
            fi
        done
        echo ""
        read -p "確定要刪除這些分支嗎？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "操作已取消"
            return 0
        fi
    fi
    
    echo "開始刪除分支..."
    local deleted_count=0
    echo "$branches" | while read -r branch; do
        if [ -n "$branch" ]; then
            git branch -D "$branch"
            if [ $? -eq 0 ]; then
                echo "✓ 已刪除分支: $branch"
                ((deleted_count++))
            else
                echo "✗ 刪除分支失敗: $branch"
            fi
        fi
    done
    echo "完成"
}

clean_ab_branches "$@"