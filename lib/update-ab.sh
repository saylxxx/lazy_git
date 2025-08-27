#!/bin/bash

# 更新所有本地分支
# 使用方法: update-ab [-q|--quiet]
# 它會在不同的工作目錄中檢出每個本地分支並執行 git pull
# 使用 -q 可減少輸出訊息

# 引用路徑處理器
source "$(dirname "$0")/path-helper.sh"

# 取得正確的 config.sh 路徑
CONFIG_PATH=$(get_config_path)

# 引用共用函數
source "$CONFIG_PATH"
source "$(dirname "$0")/common.sh"

# 確保目錄存在
ensure_home_directory

update_all_branches() {
    local quiet_mode=false
    
    # 處理參數
    if [ "$1" = "-q" ] || [ "$1" = "--quiet" ]; then
        quiet_mode=true
    fi
    
    # 清理鎖定檔案
    rm -f .git/index.lock
    rm -f .git/ORIG_HEAD.lock

    current_branch=$(git symbolic-ref --short HEAD)
    if [ "$quiet_mode" = false ]; then
        echo "當前分支: $current_branch"
    fi

    git stash -u > /dev/null 2>&1

    temp_dir=$(mktemp -d)
    if [ "$quiet_mode" = false ]; then
        echo "創建臨時目錄: $temp_dir"
        echo "開始更新所有分支..."
        echo "=============================="
    fi

    local updated_count=0
    local failed_count=0

    for branch in $(git branch --format='%(refname:short)' | grep -v "$current_branch"); do
        worktree_dir="$temp_dir/$branch"
        if [ "$quiet_mode" = false ]; then
            echo "更新分支: $branch"
        fi
        
        if git worktree add $worktree_dir $branch > /dev/null 2>&1; then
            if (cd $worktree_dir && git pull > /dev/null 2>&1); then
                if [ "$quiet_mode" = false ]; then
                    echo "✓ $branch 更新成功"
                fi
                ((updated_count++))
            else
                if [ "$quiet_mode" = false ]; then
                    echo "✗ $branch 更新失敗"
                fi
                ((failed_count++))
            fi
            git worktree remove $worktree_dir > /dev/null 2>&1
        else
            if [ "$quiet_mode" = false ]; then
                echo "✗ $branch 建立工作樹失敗"
            fi
            ((failed_count++))
        fi
        sleep 1
    done

    if [ "$quiet_mode" = false ]; then
        echo "=============================="
        echo "切換回: $current_branch"
    fi
    git checkout $current_branch > /dev/null 2>&1

    git stash pop > /dev/null 2>&1

    rm -rf $temp_dir
    if [ "$quiet_mode" = false ]; then
        echo "刪除臨時目錄: $temp_dir"
        echo ""
        echo "總結："
        echo "- 成功更新: $updated_count 個分支"
        echo "- 更新失敗: $failed_count 個分支"
        echo "完成"
    else
        echo "更新完成：成功 $updated_count 個，失敗 $failed_count 個"
    fi
}

update_all_branches "$@"